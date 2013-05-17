CHANGELOG
=========
0.1.5
-----
* Define `#to_xml` method for `OCF::Container` and `Publication::Package`

0.1.4
-----
* [Fixed-Layout Documents][fixed-layout] support
* Define `ContentDocument::XHTML#top_level?`
* Define `Spine::Itemref#page_spread` and `#page_spread=`
* Define some utility methods around `Manifest::Item` and `Spine::Itemref`
  * `Manifest::Item#itemref`
  * `Spine::Itemref#item=`

[fixed-layout]: http://www.idpf.org/epub/fxl/

0.1.3
-----
* Add `EPUB::Parser::Utils` module
* Add a command-line tool `epub-open`
* Add support for XHTML Navigation Document
* Make `EPUB::Publication::Package::Metadata#to_hash` obsolete. Use `#to_h` instead
* Add utility methods `EPUB#description`, `EPUB#date` and `EPUB#unique_identifier`

0.1.2
-----
* Fix a bug that `Item#read` couldn't read file when `href` is percent-encoded(Thanks, [gambhiro][]!)

[gambhiro]: https://github.com/gambhiro

0.1.1
-----
* Parse package@prefix and attach it as `Package#prefix`
* `Manifest::Item#iri` was removed. It have existed for files in unzipped epub books but now EPUB Parser retrieves files from zip archive directly. `#href` now returns `Addressable::URI` object.
* `Metadata::Link#iri`: ditto.
* `Guide::Reference#iri`: ditto.
