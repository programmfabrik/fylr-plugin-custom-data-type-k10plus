> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# fylr-plugin-custom-data-type-k10plus

This is a plugin for [fylr](https://docs.fylr.io/) with Custom Data Type `CustomDataTypek10plus` for references to entities of the [Gemeinsame Datenbank k10plus](https://kxp.k10plus.de/).

⚠️ For easydb5-instances use [easydb-custom-data-type-gvk](https://github.com/programmfabrik/easydb-custom-data-type-gvk).

The Plugins uses <https://ws.gbv.de/suggest/csl2/> for the autocomplete-suggestions.

Without explicit configuration, default database is "opac-de-627", which is the webview of k10plus.
Choose databases from this List: http://uri.gbv.de/database/)

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-k10plus/releases/latest/download/customDataTypek10plus.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-k10plus/releases/).


## configuration

As defined in `manifest.master.yml` this datatype can be configured:

* schema config
   * database
       * example: "K10plus-Katalogisierungsdatenbank=k10plus|MEDLINE=medline|"

* mask config
    * editordisplay: default or condensed (oneline)
    * database_overwrite
        * overwrite database-configuration from schema

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptSource
    * database-notation 
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard
* facetTerm
    * custom facets, which support multilingual facetting

## updater

Note: The automatic nightly updater can only work if the URIs contain the database name and the PPN and the database name is in the above list.
The URIs must have the following format: http://uri.gbv.de/document/{databasename}:ppn:{ppn}

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/fylr-plugin-custom-data-type-k10plus>.
