== DESCRIPTION:

Simple HTML to ePub converter.

== FEATURES/PROBLEMS:

Few samples to get started:

* Git User's Manual

    repub -x 'title://h1' -x 'toc://div[@class="toc"]/dl' -x 'toc_item:dt' -x 'toc_section:following-sibling::*[1]/dl' \
        http://www.kernel.org/pub/software/scm/git/docs/user-manual.html

* Project Gutenberg's THE ADVENTURES OF SHERLOCK HOLMES

    repub -x 'title:div[@class='book']//h1' -x 'toc://table' -x 'toc_item://tr' \
        -X '//pre' -X '//hr' -X '//body/h1' -X '//body/h2' \
	    http://www.gutenberg.org/dirs/etext99/advsh12h.htm

* Project Gutenberg's ALICE'S ADVENTURES IN WONDERLAND

    repub -x 'title:body/h1' -x 'toc://table' -x 'toc_item://tr' \
	    -X '//pre' -X '//hr' -X '//body/h4' \
	    http://www.gutenberg.org/files/11/11-h/11-h.htm

* The Gelug-Kagyu Tradition of Mahamudra from Berzin Archives

    repub http://www.berzinarchives.com/web/x/prn/p.html_680632258.html

== SYNOPSIS:

Usage: repub [options] url

General options:
  -D, --downloader NAME            Which downloader to use to get files (wget or httrack).
                                   Default is wget.
  -o, --output PATH                Output path for generated ePub file.
                                   Default is /Users/dg/Projects/repub/<Parsed_Title>.epub
  -w, --write-profile NAME         Save given options for later reuse as profile NAME.
  -l, --load-profile NAME          Load options from saved profile NAME.
  -W, --write-default              Save given options for later reuse as default profile.
  -L, --list-profiles              List saved profiles.
  -C, --cleanup                    Clean up download cache.
  -v, --verbose                    Turn on verbose output.
  -q, --quiet                      Turn off any output except errors.
  -V, --version                    Show version.
  -h, --help                       Show this help message.

Parser options:
  -x, --selector NAME:VALUE        Set parser XPath selector NAME to VALUE.
                                   Recognized selectors are: [title toc toc_item toc_section]
  -m, --meta NAME:VALUE            Set publication information metadata NAME to VALUE.
                                   Valid metadata names are: [creator date description
                                   language publisher relation rights subject title]
  -F, --no-fixup                   Do not attempt to make document meet XHTML 1.0 Strict.
                                   Default is to try and fix things that are broken. 
  -e, --encoding NAME              Set source document encoding. Default is to autodetect.

Post-processing options:
  -s, --stylesheet PATH            Use custom stylesheet at PATH to add or override existing
                                   CSS references in the source document.
  -X, --remove SELECTOR            Remove source element using XPath selector.
                                   Use -X- to ignore stored profile.
  -R, --rx /PATTERN/REPLACEMENT/   Edit source HTML using regular expressions.
                                   Use -R- to ignore stored profile.
  -B, --browse                     After processing, open resulting HTML in default browser.

== DEPENDENCIES:

* Builder (https://rubyforge.org/projects/builder/)
* Nokogiri (http://nokogiri.rubyforge.org/nokogiri/)
* rchardet (https://rubyforge.org/projects/rchardet/)
* launchy (http://copiousfreetime.rubyforge.org/launchy/)

* wget or httrack
* zip (Info-ZIP)

== INSTALL:

    gem install repub

== LICENSE:

(The MIT License)

Copyright (c) 2009 Invisible Llama <dg@invisiblellama.net>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

==
