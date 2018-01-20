// CIBot is a git repo webhook handler that runs CI jobs given an event.
//
// See docs/design/CIbot.md for a discussion.
//
// For now, it relies on Bazel's sandboxing for security. This is probably not
// enough.
//
// It listens for a webhook event from github, then runs the ci.sh script.
//
// A local directory is used to cache build artifacts between container
// invocations, which speeds things up considerably.
package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"os/user"
	"path"
	"path/filepath"
	"time"

	"github.com/kelseyhightower/envconfig"
	// TODO:Use go-github instead. See for example:
	// https://github.com/mlarraz/threshold/blob/master/threshold.go
	"github.com/google/go-github/github"
	"github.com/phayes/hookserve/hookserve"
	"github.com/sirupsen/logrus"
	git "gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
)

type gitHubCredentials struct {
	// TODO: Consolidate into a token? Are we able to clone repos with the
	// token?
	GithubUsername string `split_words:"true"`
	GithubPassword string `split_words:"true" required:true`
	GithubToken    string `split_words:"true"`
}

const (
	gitBase   = "ci/github.com/"
	cacheBase = "cache/github.com/"
	ciShell   = "ci.sh"
)

var (
	homeDir = "/"
)

var (
	port    = flag.Int("port", 8080, "port to serve requests")
	runOnce = flag.Bool("runOnce", false, "Exit after one execution, for testing")
	tmpBase = flag.Bool("tmpBase", false, "Use the Bazel test tmp directory to store files (bazel cache, git sources).")

	testShell = flag.Bool("testShell", false, "Use a ci.sh from $TEST_SRCDIR")
)

func init() {
	usr, err := user.Current()
	if err != nil {
		return
	}
	homeDir = usr.HomeDir
}

// commandWithLog takes a cmd object and a logrus logger, executes the command, and logs
// the cmd's stderr and stdout to the logrus logger.
func commandWithLog(cmd *exec.Cmd, logger *logrus.Entry) error {
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}
	multi := io.MultiReader(stdout, stderr)

	if err = cmd.Start(); err != nil {
		logger.WithField("status", err.Error()).Error("Start Error")
		return err
	}

	std := bufio.NewScanner(multi)

	lastLine := time.Now()
	for std.Scan() {
		logger.WithField("duration", time.Since(lastLine).Seconds()).Info(std.Text())
		lastLine = time.Now()
	}
	if err = cmd.Wait(); err != nil {
		logger.WithField("status", err.Error()).Error("Command Failed")
		return err
	}
	if err = std.Err(); err != nil {
		logger.WithField("status", err.Error()).Error("Error")
		return err
	}

	logger.WithField("status", cmd.ProcessState.String()).Info("Completed")
	return nil
}

// runDir obtain the absolute path of a target file. Assumes we're running by a
// container image built by bazel.
func runDir(target string) (string, error) {
	if *testShell {
		return filepath.Join(
			os.Getenv("TEST_SRCDIR"),
			"__main__",
			"ci",
			target,
		), nil
	}
	return filepath.Join(
		os.Args[0]+".runfiles",
		"__main__",
		"ci",
		target), nil
}

type ciEvent struct {
	repo    string
	branch  string
	repoURL string
	commit  string
	owner   string
}

type ciRunner struct {
	githubClient      *github.Client
	githubCredentials *gitHubCredentials
}

func (c *ciRunner) gitSetup(logger *logrus.Entry, event *ciEvent) error {
	owner, repo, commit := event.owner, event.repo, event.commit
	creds := c.githubCredentials

	auth := ""
	if creds.GithubUsername != "" || creds.GithubPassword != "" {
		auth = fmt.Sprintf("%s:%s@", creds.GithubUsername, creds.GithubPassword)
	}
	repoAddress := fmt.Sprintf("https://%sgithub.com/%s/%s.git", auth, owner, repo)
	base := homeDir
	if *tmpBase {
		base = os.Getenv("TEST_TMPDIR")
	}
	localGitDir := path.Join(base, gitBase, owner, repo)
	localCacheDir := path.Join(base, cacheBase, owner, repo)

	os.MkdirAll(localCacheDir, 0755)

	log.Println("Opening git directory", localGitDir)
	r, err := git.PlainOpen(localGitDir)
	if err != nil {
		logger.Infoln("Cloning", repoAddress)
		r, err = git.PlainClone(localGitDir, false, &git.CloneOptions{
			URL:               repoAddress,
			RecurseSubmodules: git.DefaultSubmoduleRecursionDepth,
		})
	}
	if err != nil {
		// Nuke the directory because it might have the wrong auth bits and
		// the next attempt should have a fresh start.
		os.RemoveAll(localGitDir)
		return fmt.Errorf("PlainClone of %q failed: %v", repoAddress, err)
	}

	logger.Infoln("Fetching")
	err = r.Fetch(&git.FetchOptions{RemoteName: "origin"})
	if err != git.NoErrAlreadyUpToDate && err != nil {
		return fmt.Errorf("Git Fetch failed: %v", err)
	}
	w, err := r.Worktree()
	if err != nil {
		return fmt.Errorf("Could not obtain worktree: %v", err)
	}

	logger.Infoln("checkout", commit)
	err = w.Checkout(&git.CheckoutOptions{
		Hash: plumbing.NewHash(commit),
	})
	if err != nil {
		return fmt.Errorf("Checkout failed: %v", err)
	}
	if err := os.Chdir(localGitDir); err != nil {
		return fmt.Errorf("chdir %v: %v", localGitDir, err)
	}
	return nil
}

func (c *ciRunner) SetRepoStatus(ctx context.Context, event *ciEvent, status string, description string) error {
	ciContext := "https://yourbase.io/ci"
	// TODO: This should point to the CI logs.
	targetURL := "https://example.com/"
	repoStatus := &github.RepoStatus{
		State:       &status,
		Description: &description,
		Context:     &ciContext,
		TargetURL:   &targetURL,
	}
	_, _, err := c.githubClient.Repositories.CreateStatus(ctx, event.owner, event.repo, event.commit, repoStatus)
	return err
}

// runBazelCI executes a CI script for Bazel repositories. This is not safe for
// concurrent use.
func (c *ciRunner) runBazelCI(event *ciEvent) error {
	w := logrus.WithFields(logrus.Fields{
		"owner":   event.owner,
		"repoURL": event.repoURL,
		"commit":  event.commit,
		"branch":  event.branch,
	})
	w.Info("Running CI command")
	if err := c.gitSetup(w, event); err != nil {
		w.Errorf("Failed to setup git: %v", err)
		return err
	}
	runfile, err := runDir(ciShell)
	if err != nil {
		w.Errorf("CI shell failed: %v", err)
		return err
	}
	log.Println("running ci command", runfile)
	cmd := exec.Command(runfile)
	env := os.Environ()
	if *tmpBase {
		env = append(env, fmt.Sprintf("CACHE_DIR=%s", os.Getenv("TEST_TMPDIR")))
	} else {
		env = append(env, fmt.Sprintf("CACHE_DIR=%s", filepath.Join(os.Getenv("HOME"), "bazel-cache")))
	}
	cmd.Env = env
	return commandWithLog(cmd, w)
}

func main() {
	flag.Parse()

	creds := new(gitHubCredentials)
	err := envconfig.Process("secret", creds)
	if err != nil {
		log.Fatal(err.Error())
	}
	runner := &ciRunner{
		githubClient:      newGithubClient(creds),
		githubCredentials: creds,
	}

	server := hookserve.NewServer()
	server.Port = *port
	// TODO: Use a secret.
	// server.Secret = hookSecret
	server.GoListenAndServe()
	log.Println("Starting server on port", *port)

	// This runs one Bazel command at a time. That's fine for now, but I
	// don't know what GitHub and the loadbalancer will do if they push
	// an event and we're busy building the last one. In a perfect world,
	// the loadbalancer would transparently retry in a different replica
	// (hooray, automatic CI scalability), but I don't know if that's the case.

	for {
		select {
		case event := <-server.Events:
			ctx := context.Background()
			ev := &ciEvent{
				commit:  event.Commit,
				branch:  event.Branch,
				owner:   event.Owner,
				repo:    event.Repo,
				repoURL: fmt.Sprintf("github.com/%v/%v", event.Owner, event.Repo),
			}
			if err := runner.SetRepoStatus(ctx, ev, "pending", "CI test running"); err != nil {
				log.Printf("SetRepoStatus: %v", err)
			}
			status := "success"
			err := runner.runBazelCI(ev)
			if err != nil {
				log.Printf("bazel CI failed: %s", err)
				status = "failure"
			}
			if err := runner.SetRepoStatus(ctx, ev, status, "CI test finished"); err != nil {
				log.Printf("SetRepoStatus: %v", err)
			}
			if *runOnce {
				if err != nil {
					log.Fatal(err)
				}
				os.Exit(0)
			}
		}
	}

}
