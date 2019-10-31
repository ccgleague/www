# www
Our public website

### Developer Notes

The Makefile has most of the things you'd want to do, including:

```
$ make
bucket                         Create a new S3 bucket using the configuration in conf/*
clean                          Remove pycache files
deploy                         Deploy webapp to S3 bucket
server                         Run a development web server with livereload on port 35729
solve                          Re-solve locked project dependencies from deps.txt
```
