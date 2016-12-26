# Cirneco: command-line client for DataCite MDS

[![Gem Version](https://badge.fury.io/rb/cirneco.svg)](https://badge.fury.io/rb/cirneco)
[![Build Status](https://travis-ci.org/datacite/cirneco.svg?branch=master)](https://travis-ci.org/datacite/cirneco)
[![Code Climate](https://codeclimate.com/github/datacite/cirneco/badges/gpa.svg)](https://codeclimate.com/github/datacite/cirneco)
[![Test Coverage](https://codeclimate.com/github/datacite/cirneco/badges/coverage.svg)](https://codeclimate.com/github/datacite/cirneco/coverage)

Cirneco is a command-line client for the [DataCite Metadata Store](https://mds.datacite.org) (MDS), written as Ruby gem. Uses the MDS API, and includes several utlity functions.

## Features

The following functionality is supported:

* the MDS API (DOI, Metadata and Media APIs) is fully supported
* generates valid metadata, using Schema 4.0 (currently only partial support of available metadata fields)
* generates a DOI name to be used for registration, using a random number that is [Base32 Crockford encoded](http://www.crockford.com/wrmg/base32.html) and includes a checksum

## Requirements

* valid username and password for DataCite MDS account (production and/or test system)

## Installation

The usual way with Bundler: add the following to your `Gemfile` to install the current version of the gem:

```ruby
gem 'cirneco'
```

Then run `bundle install` to install into your environment.

You can also install the gem system-wide in the usual way:

```bash
gem install cirneco
```

## Configuration

Configure ENV variables `MDS_USERNAME`, `MDS_PASSWORD` and `PREFIX`, e.g. by storing them in file `.env` (see `.env.xample`) in same directory you run the command.

## DataCite MDS API Commands

The commands map to the commands available in the [DataCite MDS API](https://mds.datacite.org/static/apidoc).

Return all DOIs registered for the data center
```
cirneco doi get all
```

Return URL registered for DOI in the handle system
```
cirneco doi get 10.5555/1234
```

Save metadata for DOI into file `1234.xml` in same directory
```
cirneco metadata get 10.5555/1234
```

Post metadata from file `1234.xml` in same directory
```
cirneco metadata post 1234.xml
```

Delete metadata for DOI (set `is_active` flag to false)
```
cirneco metadata delete 10.5555/1234
```

Save media information for DOI into file `1234.txt` in same directory
```
cirneco media get 10.5555/1234
```

Post media information from file `1234.txt` in same directory
```
cirneco media post 1234.xml
```

## Utility Commands
Commands to generate and check random DOIs, and for registering DOIs using
markdown files with metadata in YAML frontmatter

Generate a random DOI in the format `xxxx-xxxy` where `y` is the checksum
```
cirneco doi generate
```

Decode DOI
```
cirneco doi decode 10.5072/0000-03VC
```

Check DOI for valid checksum
```
cirneco doi check 10.5072/0000-03VC
```

Mint a DOI with metadata from a markdown file with YAML frontmatter
```
cirneco doi mint /source/posts/cool-dois.html.md
```

Mint DOIs with metadata for all markdown files in a folder
```
cirneco doi mint /source/posts
```

Mint a DOI and hide metadata from a markdown file with YAML frontmatter
```
cirneco doi mint_and_hide /source/posts/cool-dois.html.md
```

Mint DOIs and hide metadata for all markdown files in a folder
```
cirneco doi mint_and_hide /source/posts
```

Hide DOI metadata for a markdown file with YAML frontmatter
```
cirneco doi hide /source/posts/cool-dois.html.md
```

Hide DOIs with metadata for all markdown files in a folder
```
cirneco doi hide /source/posts
```

## Development

We use rspec for unit testing:

```
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/datacite/cirneco/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License
**cirneco** is released under the [MIT License](https://github.com/datacite/cirneco/blob/master/LICENSE.md).
