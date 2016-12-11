# Cirneco: Ruby command-line client for DataCite Metadata Store (MDS)

[![Gem Version](https://badge.fury.io/rb/cirneco.svg)](https://badge.fury.io/rb/cirneco)
[![Build Status](https://travis-ci.org/datacite/cirneco.svg?branch=master)](https://travis-ci.org/datacite/cirneco)
[![Code Climate](https://codeclimate.com/github/datacite/cirneco/badges/gpa.svg)](https://codeclimate.com/github/datacite/cirneco)
[![Test Coverage](https://codeclimate.com/github/datacite/cirneco/badges/coverage.svg)](https://codeclimate.com/github/datacite/cirneco/coverage)

Cirneco is a command-line client for the DataCite Metadata Store (MDS), written as Ruby gem. Uses the MDS API, and includes several utlity functions.

## Features

The following functionality is supported:

* the MDS API (DOI, Metadata and Media APIs) is fully supported
* generates valid metadata, using Schema 4.0 (currently only partial support of available metadata fields)
* generates a DOI name to be used for registration, using [Base32 Crockford encoded](https://github.com/levinalex/base32) sequential numbers that include a checksum

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

## Use

TBD.

## License

[MIT](license.md)
