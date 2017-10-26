package housekeeper

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

func main() {
	repo := os.Args[1]
	token := os.Getenv("GITHUB_ACCESS_TOKEN")
	owner := os.Getenv("OWNER")

	if token == "" {
		fmt.Println("GITHUB_ACCESS_TOKEN not set, exiting")
		os.Exit(1)
	}
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: token},
	)
	tc := oauth2.NewClient(ctx, ts)

	client := github.NewClient(tc)

	listOpts := github.ListOptions{
		Page:    1,
		PerPage: 30,
	}

	// 14 days
	deadline := time.Now().AddDate(0, 0, -14)

	for {
		rels, resp, err := client.Repositories.ListReleases(ctx, owner, repo, &listOpts)
		if err != nil {
			panic(err)
		}

		for _, r := range rels {
			created := r.GetCreatedAt()
			if !created.Before(deadline) {
				fmt.Printf("Skipping younger draft release %s: | %s\n", r.GetTagName(), created.Format("2006-01-02"))
				continue
			}
			fmt.Printf("Release `%s`| Tag `%s` going do be deleted\n", r.GetName(), r.GetTagName())
			// Delete GitHub Release
			if _, e := client.Repositories.DeleteRelease(ctx, owner, repo, *r.ID); e != nil {
				log.Fatalf("Deleting release %s failed; error: %s", r.GetName(), e)
			}
			// Delete Git tag
			if _, e := client.Git.DeleteRef(ctx, owner, repo, "tags/"+*r.TagName); e != nil {
				// Draft release dose not have git tag sometimes.
				log.Printf("Deleting tag %s failed; error: %s", *r.TagName, e)
			}
		}

		if resp.NextPage == 0 {
			break
		}

		listOpts.Page = resp.NextPage
	}
}
