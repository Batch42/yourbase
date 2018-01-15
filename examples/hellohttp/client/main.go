package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path"
)

func showUsage() {
	cmd := path.Base(os.Args[0])
	fmt.Printf("usage:\n\t%v [url...]\n", cmd)
}

func main() {
	if len(os.Args) < 2 {
		showUsage()
		os.Exit(1)
	}
	for _, target := range os.Args[1:] {
		fmt.Fprintln(os.Stderr, "fetching", target)
		resp, err := http.Get(target)
		defer resp.Body.Close()
		if err != nil {
			log.Fatalf("Error fetching URL %v: %v", target, err)
		}
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Fatalf("Error reading body: %v", err)
		}
		fmt.Println(string(body))
	}
}
