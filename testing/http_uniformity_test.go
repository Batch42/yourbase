// http_uniformity runs blackbox tests against a target HTTP server and checks
// that it follows best practices from https://yourbase.io/uniformity.
//
// It supports different types of servers, such as Go and Spring servers.
package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path"
	"testing"
	"time"
)

func showUsage() {
	cmd := path.Base(os.Args[0])
	fmt.Printf("usage:\n\t%v [httpServerBinaryPath]\n", cmd)
}

type AppChecker interface {
	Type() string
	AllChecks() []error
	HealthCheck() error
	TargetURL() string
}

type FallbackAppChecker struct{}

func (FallbackAppChecker) Type() string {
	return "Unknown"
}

func (FallbackAppChecker) TargetURL() string {
	return "http://localhost:8080/"
}

func (f *FallbackAppChecker) AllChecks() (errs []error) {
	if err := f.HealthCheck(); err != nil {
		errs = append(errs, err)
	}
	return errs
}

func (f *FallbackAppChecker) HealthCheck() error {
	// TODO: The healthchecker should poll on the server's port and have a
	// timeout of 10s or so.
	time.Sleep(2 * time.Second)

	targetURL := f.TargetURL()
	fmt.Fprintln(os.Stderr, "fetching", targetURL)
	resp, err := http.Get(targetURL)
	if err != nil {
		return fmt.Errorf("Error fetching URL %v: %v", targetURL, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("Unexpected status code fetching %v: %v", targetURL, err)
	}
	if _, err := ioutil.ReadAll(resp.Body); err != nil {
		return fmt.Errorf("Error reading body from %v: %v", targetURL, err)
	}
	return nil

}

type GoAppChecker struct {
	FallbackAppChecker
}

func (GoAppChecker) Type() string {
	return "GoApp"
}

func (g *GoAppChecker) TargetURL() string {
	return fmt.Sprintf("%s/WRONG", g.FallbackAppChecker.TargetURL())
}

func runBinary(binaryPath string) (err error) {
	cmd := exec.Command(binaryPath)
	cmd.Stdout = os.Stdout
	if err := cmd.Start(); err != nil {
		return err
	}
	return nil
}

func TestUniformity(t *testing.T) {
	if len(os.Args) < 2 {
		showUsage()
		os.Exit(1)
	}
	dir := path.Dir(os.Args[0])
	for _, bin := range os.Args[1:] {
		// TODO: Consider using TEST_SRCDIR instead.
		binaryPath := path.Join(dir, path.Base(bin))

		if err := runBinary(binaryPath); err != nil {
			t.Fatalf("could not run binary %v: %v", binaryPath, err)
		}

		// TODO: define checker type based on CLI params or by doing tests on the provided binary.
		framework := &GoAppChecker{}
		fmt.Println("Found framework of type", framework.Type())
		errs := framework.AllChecks()
		if len(errs) > 0 {
			for _, err := range errs {
				t.Errorf("Check fails: %v", err)
			}
		}
		t.Logf("Done")
	}
}
