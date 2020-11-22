package main

import (
	"time"
)

type Post struct {
	Title       string    `yaml:title`
	Author      string    `yaml:author`
	Date        time.Time `yaml:date`
	Description string    `yaml:description`
	Filename    string
}
