#   Copyright (C) 2011-2014  Povilas Kanapickas <povilas@radix.lt>
#
#   This file is part of cppreference-doc
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see http://www.gnu.org/licenses/.

SHELL := /bin/bash

#Common prefixes

prefix = /usr
datarootdir = $(prefix)/share
docdir = $(datarootdir)/cppreference/doc
bookdir = $(datarootdir)/devhelp/books

qhelpgenerator = qhelpgenerator

#Version

VERSION := $(shell date +%Y%m%d)

#STANDARD RULES

all: doc_devhelp doc_qch doc_doxygen

DISTFILES = \
		commands/ \
		gadgets/ \
		headers/ \
		index_transform/ \
		images/ \
		reference/ \
		skins/ \
		tests/ \
		build_link_map.py \
		ddg_parse_html.py \
		devhelp2qch.py \
		fix_devhelp-links.py \
		index2autolinker.py \
		index2browser.py \
		index2ddg.py \
		index2devhelp.py \
		index2doxygen-tag.py \
		index2highlight.py \
		index2search.py \
		index-chapters-c.xml \
		index-chapters-cpp.xml \
		index-cpp-search-app.txt \
		index-functions.README \
		index-functions-c.xml \
		index-functions-cpp.xml \
		link_map.py \
		preprocess.py \
		preprocess-css.css \
		test.sh \
		xml_utils.py \
		Makefile \
		README.md

CLEANFILES = \
		output

TAR_FORMAT := gz
TAR_OPTION := z
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	TAR_FORMAT := xz
	TAR_OPTION := J
endif

clean:
		rm -rf $(CLEANFILES)

check:

dist: clean
	mkdir -p cppreference-doc-$(VERSION)
	cp -r $(DISTFILES) cppreference-doc-$(VERSION)
	tar c$(TAR_OPTION)f cppreference-doc-$(VERSION).tar.$(TAR_FORMAT) cppreference-doc-$(VERSION)
	rm -rf cppreference-doc-$(VERSION)

install: all
	# install the devhelp documentation
	pushd output/reference > /dev/null; \
	find . -type f \
		-exec install -DT -m 644 {} $(DESTDIR)$(docdir)/html/{} \; ; \
	popd > /dev/null

	install -DT -m 644 output/cppreference-doc-en-c.devhelp2 \
		$(DESTDIR)$(bookdir)/cppreference-doc-en-c/cppreference-doc-en-c.devhelp2
	install -DT -m 644 output/cppreference-doc-en-cpp.devhelp2 \
		$(DESTDIR)$(bookdir)/cppreference-doc-en-cpp/cppreference-doc-en-cpp.devhelp2
	install -DT -m 644 output/cppreference-doxygen-local.tag.xml \
		$(DESTDIR)$(bookdir)/cppreference-doxygen-local.tag.xml
	install -DT -m 644 output/cppreference-doxygen-web.tag.xml \
		$(DESTDIR)$(bookdir)/cppreference-doxygen-web.tag.xml

	# install the .qch (Qt Help) documentation
	install -DT -m 644 output/cppreference-doc-en-cpp.qch \
		$(DESTDIR)$(docdir)/qch/cppreference-doc-en-cpp.qch

uninstall:
	rm -rf $(DESTDIR)$(docdir)
	rm -rf $(DESTDIR)$(bookdir)

release: all
	rm -rf release
	mkdir -p release

	# zip the distributable
	mkdir -p cppreference-doc-$(VERSION)
	cp -r $(DISTFILES) cppreference-doc-$(VERSION)
	tar c$(TAR_OPTION)f release/cppreference-doc-$(VERSION).tar.$(TAR_FORMAT) cppreference-doc-$(VERSION)
	zip -qr release/cppreference-doc-$(VERSION).zip cppreference-doc-$(VERSION)
	rm -rf cppreference-doc-$(VERSION)

	# zip the html output
	pushd output; \
	tar c$(TAR_OPTION)f ../release/html-book-$(VERSION).tar.$(TAR_FORMAT) reference \
		cppreference-doxygen-local.tag.xml cppreference-doxygen-web.tag.xml ; \
	zip -qr ../release/html-book-$(VERSION).zip reference \
		cppreference-doxygen-local.tag.xml cppreference-doxygen-web.tag.xml ; \
	popd

	# zip qch
	pushd output; \
	tar c$(TAR_OPTION)f ../release/qch-book-$(VERSION).tar.$(TAR_FORMAT) cppreference-doc-en-cpp.qch; \
	zip -qr ../release/qch-book-$(VERSION).zip cppreference-doc-en-cpp.qch; \
	popd

#WORKER RULES
doc_html: output/reference

doc_devhelp: output/cppreference-doc-en-c.devhelp2 output/cppreference-doc-en-cpp.devhelp2

doc_qch: output/cppreference-doc-en-cpp.qch

doc_doxygen: output/cppreference-doxygen-web.tag.xml output/cppreference-doxygen-local.tag.xml

#builds the title<->location map
output/link-map.xml: output/reference
	./build_link_map.py

#build the .devhelp2 index
output/cppreference-doc-en-c.devhelp2: \
		output/reference \
		output/link-map.xml
	./index2devhelp.py $(docdir)/html index-chapters-c.xml \
		"C Standard Library reference" cppreference-doc-en-c c \
		index-functions-c.xml output/devhelp-index-c.xml
	./fix_devhelp-links.py output/devhelp-index-c.xml \
		output/cppreference-doc-en-c.devhelp2

output/cppreference-doc-en-cpp.devhelp2: \
		output/reference \
		output/link-map.xml
	./index2devhelp.py $(docdir)/html index-chapters-cpp.xml \
		"C++ Standard Library reference" cppreference-doc-en-cpp cpp \
		index-functions-cpp.xml output/devhelp-index-cpp.xml
	./fix_devhelp-links.py output/devhelp-index-cpp.xml \
		output/cppreference-doc-en-cpp.devhelp2

#build the .qch (QT help) file
output/cppreference-doc-en-cpp.qch: output/qch-help-project-cpp.xml
	#qhelpgenerator only works if the project file is in the same directory as the documentation
	ln $< output/reference_cssless/qch.qhp

	cd output/reference_cssless; \
	$(qhelpgenerator) qch.qhp -o ../$(@F)

	rm -f output/reference_cssless/qch.qhp

output/qch-help-project-cpp.xml: devhelp2qch.py output/cppreference-doc-en-cpp.devhelp2 output/qch-files.xml
	#create the project (copies the file list)
	./$(word 1,$^) --src=$(word 2,$^) --file_list=$(word 3,$^) --virtual_folder=cpp --dst=$@

output/qch-files.xml: | output/reference_cssless
	(echo '<?xml version="1.0" encoding="UTF-8"?><files>'; \
	 cd $^; \
	 find -type f -not -iname '*.ttf' -printf '  <file>%p</file>\n' | LC_ALL=C sort; \
	 echo '</files>') > $@

# build doxygen tag file
output/cppreference-doxygen-local.tag.xml: index2doxygen-tag.py output/link-map.xml index-functions-cpp.xml index-chapters-cpp.xml | output
	./$^ $@

output/cppreference-doxygen-web.tag.xml: index2doxygen-tag.py index-functions-cpp.xml index-chapters-cpp.xml | output
	./$(word 1,$^) web $(wordlist 2, 3, $^) $@

output:
	mkdir -p $@

#create preprocessed archive
output/reference: preprocess.py | output
	./$^ --src reference --dst $@

output/reference_cssless: preprocess_qch.py | output/reference
	./$^ --src $| --dst $@

# create indexes for the wiki
.PHONY: indexes
indexes: output/indexes/highlight-cpp output/indexes/highlight-c output/indexes/search-cpp output/indexes/search-c output/indexes/autolink-cpp output/indexes/autolink-c 

output/indexes: | output
	mkdir -p $@

output/indexes/highlight-cpp: index2highlight.py index-functions-cpp.xml | output/indexes
	./$^ $@

output/indexes/highlight-c: index2highlight.py index-functions-c.xml | output/indexes
	./$^ $@

output/indexes/search-cpp: index2search.py index-functions-cpp.xml index-cpp-search-app.txt | output/indexes
	./$(word 1,$^) $(word 2,$^) $@
	cat $(word 3,$^) >> $@

output/indexes/search-c: index2search.py index-functions-c.xml | output/indexes
	./$^ $@

output/indexes/autolink-cpp: index2autolinker.py index-functions-cpp.xml | output/indexes
	./$^ $@

output/indexes/autolink-c: index2autolinker.py index-functions-c.xml | output/indexes
	./$^ $@

#redownloads the source documentation directly from en.cppreference.com
.PHONY: source
source: reference/wget.done reference/cppreference-export-ns0,4,8,10.xml

reference:
	mkdir $@

reference/wget.done: | reference
	# The use of [true] below is unfortunate.  If wget gets an
	# error (e.g., a 404), then when it finishes, the exit code
	# will be rc=8.  Unfortunately, sometimes bad templates will
	# generate bogus links.  See
	# https://en.cppreference.com/mwiki/index.php?title=Cppreference_talk:FAQ&diff=154683&oldid=151312
	# for details
	regex='index\.php' \
	regex+='|/(Special|Talk|Help|File|Cppreference):' \
	regex+='|/(WhatLinksHere|Template|Category):' \
	regex+='|(action|printable)=' \
	regex+='|en.cppreference.com/book' ; \
	wget --debug --output-file=$(@D)/wget.log \
	  --adjust-extension --page-requisites --convert-links \
	  --force-directories --recursive --level=inf \
	  --span-hosts --domains=en.cppreference.com,upload.cppreference.com \
	  --reject-regex=$$regex \
	  --timeout=10 \
	  --retry-connrefused --waitretry=10 \
	  --directory-prefix=$(@D) \
	  https://en.cppreference.com/w/ ; \
	touch $@

reference/cppreference-export-ns0,4,8,10.xml: export.py | reference
	./$^ --url=https://en.cppreference.com/mwiki $@ 0 4 8 10
