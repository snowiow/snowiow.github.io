package main

import (
	"fmt"
	"github.com/gorilla/feeds"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"os"
	"strings"
	"time"
)

const DOMAIN = "https://snow-dev.com"

func main() {
	now := time.Now()

	feed := feeds.Feed{
		Title:       "snow-dev.com",
		Link:        &feeds.Link{Href: DOMAIN},
		Description: "A blog about linux, vim, devops and various other tech topics",
		Author:      &feeds.Author{Name: "Marcel Patzwahl", Email: "marcel.patzwahl@posteo.de"},
		Created:     now,
	}

	posts := getPosts()
	for _, post := range posts {
		url := fmt.Sprintf("%s/posts/%s.html", DOMAIN, post.Filename)
		item := feeds.Item{
			Title:       post.Title,
			Author:      &feeds.Author{Name: post.Author},
			Created:     post.Date,
			Link:        &feeds.Link{Href: url},
			Description: post.Description,
		}
		feed.Items = append(feed.Items, &item)
	}
	rss, err := feed.ToRss()
	if err != nil {
		fmt.Printf("Couldn't generate RSS Feed\n%s", err)
		os.Exit(1)
	}
	err = ioutil.WriteFile("docs/rss.xml", []byte(rss), 0755)
	if err != nil {
		fmt.Printf("Couldn't write rss.xml.\n%s", err)
		os.Exit(1)
	}
	atom, err := feed.ToAtom()
	if err != nil {
		fmt.Printf("Couldn't generate Atom Feed\n%s", err)
		os.Exit(1)
	}
	err = ioutil.WriteFile("docs/atom.xml", []byte(atom), 0755)
	if err != nil {
		fmt.Printf("Couldn't write atom.xml.\n%s", err)
		os.Exit(1)
	}
}

func getPosts() []*Post {
	dir := "./content/posts/"
	fileInfo, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Printf("Couldn't read from directory %s\n", dir)
		os.Exit(1)
	}
	var posts []*Post
	for _, info := range fileInfo {
		filename := info.Name()
		content, err := ioutil.ReadFile(dir + filename)
		if err != nil {
			fmt.Printf("Couldn't read file %s\n", dir+filename)
			os.Exit(1)
		}
		post := Post{}
		yaml.Unmarshal(content, &post)
		post.Filename = strings.TrimSuffix(filename, ".md")
		posts = append(posts, &post)
	}
	return posts
}
