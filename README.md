# Cirneco: command-line client for DataCite MDS

[![Gem Version](https://badge.fury.io/rb/cirneco.svg)](https://badge.fury.io/rb/cirneco)
[![Build Status](https://travis-ci.org/datacite/cirneco.svg?branch=master)](https://travis-ci.org/datacite/cirneco)
[![Code Climate](https://codeclimate.com/github/datacite/cirneco/badges/gpa.svg)](https://codeclimate.com/github/datacite/cirneco)
[![Test Coverage](https://codeclimate.com/github/datacite/cirneco/badges/coverage.svg)](https://codeclimate.com/github/datacite/cirneco/coverage)

Cirneco is a command-line client for the DataCite Metadata Store (MDS), written as Ruby gem. Uses the MDS API, and includes several utlity functions.

## Features

The following functionality is supported:

* the MDS API (DOI, Metadata and Media APIs) is fully supported
* generates valid metadata, using Schema 4.0 (currently only partial support of available metadata fields)
* generates a DOI name to be used for registration, using a random number that is [Base32 Crockford encoded](https://github.com/levinalex/base32) and includes a checksum

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

Configure ENV variables `MDS_USERNAME`, `MDS_PASSWORD` and `PREFIX`, e.g. by storing them in file `.env` in same folder (see `.env.xample`).

## Commands

The commands map to the commands available in the [DataCite MDS API](https://mds.datacite.org/static/apidoc), and two additional commands allow the generation and check of random DOIs.

Generate a random DOI in the format `xxxx-xxxy` where `y` is the checksum
```
cirneco doi generate
```

Check DOI for valid checksum
```
cirneco doi check 10.5555/1234
```

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

## License

[MIT](license.md)
