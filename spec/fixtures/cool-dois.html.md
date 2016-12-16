---
layout: post
title: Cool DOI's
author: mfenner
date: 2016-12-15
tags:
- doi
- featured
image: https://blog.datacite.org/images/2016/12/cool-dois.png
---
In 1998 Tim Berners-Lee coined the term cool URIs [-@https://www.w3.org/Provider/Style/URI], that is URIs that don’t change. We know that URLs referenced in the scholarly literature are often not cool, leading to link rot [@https://doi.org/10.1371/journal.pone.0115253] and making it hard or impossible to find the referenced resource.READMORE

Cool URIs are, of course, a fundamental principle behind DOIs, with the two important concepts [*resolution*](https://www.doi.org/doi_handbook/3_Resolution.html) (it is very hard to maintain a URL directly pointing at a resource) and [*policies*](https://www.doi.org/doi_handbook/6_Policies.html) (that all DOI registration agencies and organizations minting DOIs agree to maintain the redirection). The third essential element for DOIs, their [*data model*](https://www.doi.org/doi_handbook/4_Data_Model.html), is not directly about persistent linking, but about the discoverability of the linked resources via standard metadata in a central index.

All DOIs, expressed as HTTP URI, are therefore cool URIs. So what is a cool DOI? And, furthermore, how to create and use them? To understand what a cool DOI is, we have to explain the three parts that make up a DOI:

![](/images/2016/12/doi-parts.png)

### Proxy

The proxy is not part of the DOI specification, but almost all scholarly DOIs that users encounter today will be expressed as HTTP URLs. DataCite recommends that all DOIs are displayed as permanent URLs, consistent with the recommendations of other DOI registration agencies, e.g. the [Crossref DOI display guidelines](http://www.crossref.org/02publishers/doi_display_guidelines.html). When the DOI system was originally designed, it was thought that the DOI protocol would become widely used, but that clearly has not happened and displaying DOIs as **doi:10.5281/ZENODO.31780** is therefore not recommended.

The DOI proxy enables the functionality of expressing DOIs as HTTP URIs. Users should also be aware of two these two recommendations:

* Use [doi.org](https://www.doi.org/doi_proxy/proxy_policies.html) instead of dx.doi.org as DNS name
* Use the HTTPS protocol instead of HTTP protocol

Ed Pentz from Crossref makes the case for HTTPS in a [September blog post](http://blog.crossref.org/2016/09/new-crossref-doi-display-guidelines.html). The web, and therefore also the scholarly web, is moving to HTTPS as the default. It is important that the DOI proxy redirects to HTTPS URLs, and it will take some time until all DataCite data centers use HTTPS for the landing pages their DOIs redirects to.

What many users don’t know is that doi.org is not the only proxy server for DOIs. DOIs use the handle system and any handle server will resolve a DOI, just as doi.org will resolve any handle. This means that [https://hdl.handle.net/10.5281/ZENODO.31780](https://hdl.handle.net/10.5281/ZENODO.31780) will resolve to the landing page for that DOI and that [http://doi.org/10273/BGRB5054RX05201](http://doi.org/10273/BGRB5054RX05201) is a handle (for a [IGSN](http://www.igsn.org/)) and not a DOI.

### Prefix

The DOI prefix is used as a namespace so that DOIs are globally unique without requiring global coordination for every new identifier. Prefixes in the handle system and therefore for DOIs are numbers without any semantic meaning. One lesson learned with persistent identifiers is that adding meaning to the identifier (e.g. by using a prefix with the name of the data repository) is always dangerous, because – despite best intentions – all names can change over time.

Since the DOI prefix is a namespace to keep DOIs globally unique, there is usually no need for multiple prefixes for one organization managing DOI assignment. The tricky part is that these responsibilities can change, e.g. when an organization manages multiple repositories and one of them is migrated to another organization. It therefore makes sense to assign one prefix per list of resources that always stays together, e.g. one repository. It is possible that one prefix is managed by multiple organizations (as long as they use the same DOI registration agency), but that makes DOI management more complex.

### Suffix

The suffix for a DOI can be (almost) any string. Which is both a feature and a curse. It is a feature because it gives maximal flexibility, for example when migrating existing identifiers to the DOI system. And it is a curse because it not always works well in the web context, as the list of characters allowed in a URL is limited. A good example of this are SICIs ([Serial Item and Contribution Identifier](https://en.wikipedia.org/wiki/Serial_Item_and_Contribution_Identifier)), they were defined in 1996 before the DOI system was implemented, and could then be migrated to DOIs. Unfortunately they can contain many characters that are problematic in a URL or make it difficult to validate the DOI, as in [https://doi.org/10.1002/(sici)1099-1409(199908/10)3:6/7<672::aid-jpp192>3.0.co;2-8](https://doi.org/10.1002/(sici)1099-1409(199908/10)3:6/7<672::aid-jpp192>3.0.co;2-8). A Crossref [blog post](http://blog.crossref.org/2015/08/doi-regular-expressions.html) by Andrew Gilmartin gives a good overview about the characters found in DOIs and suggests the following regular expression to check for valid DOIs:

```
/^10.\d{4,9}/[-._;()/:A-Z0-9]+$/i
```

SICIs demonstrate two other pitfalls:

* they contain semantic information (ISSN, volume, number, etc.) that may change over time, and
* they are long, difficult to transcribe, with characters not allowed in URLs, and not very human-readable.

Semantic information might also lead users to expect certain functionalities. A common pattern that we see at DataCite is to include information about the version or parent in the suffix, e.g. [https://doi.org/10.6084/M9.FIGSHARE.3501629.V1](https://doi.org/10.6084/M9.FIGSHARE.3501629.V1) or [https://doi.org/10.5061/DRYAD.0SN63/7](https://doi.org/10.5061/DRYAD.0SN63/7). While the decision on what to put into the suffix is up to each data center, we should make sure users don't think that these are functionalities of the DOI system (e.g. that adding **.V2** to any DOI name will resolve to version 2 of that resource).

Another issue to keep in mind when assigning suffixes is that DOIs – in contrast to HTTP URIs – are case-insensitive, [https://doi.org/10.5281/ZENODO.31780](https://doi.org/10.5281/ZENODO.31780) and [https://doi.org/10.5281/zenodo.31780](https://doi.org/10.5281/zenodo.31780) are the same DOI. All DOIs are [converted to upper case](https://www.doi.org/doi_handbook/2_Numbering.html#2.4) upon registration and DOI resolution, but DOIs are not consistently displayed in such a way.

### Generating cool DOIs

With all that, what should the ideal DOI look like? Its suffix should be:

* opaque without semantic information
* work well in a web environment, avoiding characters problematic in URLs
* short and human-readable
* Resistant to transcription errors
* easy to generate

On Tuesday DataCite released a tool that helps generating such a suffix, an open source command line tool called [cirneco](https://github.com/datacite/cirneco) (a lot of our open source software uses Italian dog breed names). Cirneco is a Ruby gem that can be installed via

```
gem install cirneco
```

Cirneco uses base32 encoding, as [described](http://www.crockford.com/wrmg/base32.html) by Douglas Crockford. The encoding starts with a randomly generated number to guarantee uniqueness of the identifier, and then encodes the number into a string that uses all numbers and uppercase letters. It avoids the letters I, O and L as they can be confused with the letter 1 and 0, using 32 characters (and 5 checksum characters) in total. The last character is a checksum. The resulting string from cirneco always has a length of 8 characters, in groups of 4 separated by a hyphen to help with readability. The advantage of base32 encoding over using only numbers (as for example ORCID is doing) is that the resulting string becomes much more compact, the available 7 characters (plus one for the checksum) can encode 34,359,738,367 strings, compared to 10 million when only using numbers. This number is large enough that the resulting suffix will not only be unique for a given prefix, but also unique for all DOIs (there is a very small chance to get the same random number twice, but this will be rejected when trying to register the DOI).

Another common way to generate random strings would have been universally unique identifiers ([UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier)), but they are long and not very human-readable, e.g. [https://doi.org/10.4233/UUID:6D192FE2-DE18-4556-873A-D3CD56AB96A6](https://doi.org/10.4233/UUID:6D192FE2-DE18-4556-873A-D3CD56AB96A6).

An example DOI generated by cirneco would be

```
cirneco doi generate --prefix 10.5555
10.5555/KVTD-VPWM
```

The generated DOI is short enough that it should work well in places where space is limited, providing an alternative to the [ShortDOI](http://shortdoi.org/) service which shortens existing DOIs, but does this by adding another layer on top of the DOI proxy.

Another cirneco command checks that this is a valid bas32 string using the checksum

```
cirneco doi check 10.5555/KVTD-VPWM
Checksum for 10.5555/KVTD-VPWM is valid
```

This can be used to quickly verify a DOI, e.g. in a web form or API. The Ruby base32 encoding library used by cirneco is open source ([https://github.com/datacite/base32](https://github.com/datacite/base32). I added the checksum to the existing library), and implementations of the Crockford base32 encoding pattern are available in many other languages, including [Python](https://github.com/jbittel/base32-crockford), [PHP](https://github.com/dflydev/dflydev-base32-crockford), [Javascript](https://www.npmjs.com/package/base32-crockford), [Java](http://stackoverflow.com/questions/22385467/crockford-base32-encoding-for-large-number-java-implementation), [Go](https://github.com/richardlehane/crock32) and [.NET](https://crockfordbase32.codeplex.com/).

To answer the question raised at the beginning: a cool DOI is a DOI expressed as HTTPS URI using the doi.org proxy and using a base32-encoded suffix, for example **https://doi.org/10.5555/KVTD-VPWM**. This DOI works well in a web environment, is human readable, easy to parse and detect (e.g. in text mining), and can be generated using an algorithm that is well understood and supported.

![](/images/2016/12/cool-dois.png)

### References
