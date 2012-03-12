#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Makefile for oVirt Engine Image uploader
#

NAME=ovirt-image-uploader
# ex. export APP_VERSION=1.0.0
RPM_VERSION:=$(shell echo $(APP_VERSION) | sed "s/-/_/")
# ex. export APP_RELEASE=1
RPM_RELEASE:=$(shell echo $(APP_RELEASE) | sed "s/-/_/")
SPEC_FILE_IN=ovirt-image-uploader.spec.in
SPEC_FILE=ovirt-image-uploader.spec
RPMTOP=$(shell bash -c "pwd -P")/rpmtop
NAME_VER=$(NAME)-$(RPM_VERSION)
TARBALL=$(NAME)-$(RPM_VERSION).tar.gz
SRPM=$(RPMTOP)/SRPMS/$(NAME)-$(RPM_VERSION)*.src.rpm
ARCH=noarch


CURR_DIR=$(shell bash -c "pwd -P")
all: rpm

clean:
	@for i in `find . -iname *.pyc`; do \
		rm $$i; \
	done; \
	for i in `find . -iname *.pyo`; do \
		rm $$i; \
	done; \
	rm -rf $(SPEC_FILE) $(RPMTOP) $(TARBALL)

install: create_dirs install_image_uploader

tarball: $(TARBALL)
$(TARBALL):
	tar --transform 's,^,/$(NAME_VER)/,S' -z -c -f $(TARBALL) `git ls-files`

srpm: $(SRPM)

$(SRPM): tarball $(SPEC_FILE_IN)
	sed 's/^Version:.*/Version: $(RPM_VERSION)/' $(SPEC_FILE_IN) > $(SPEC_FILE)
	sed -i -e's/^Release:.*/Release: $(RPM_RELEASE)%{?dist}/' $(SPEC_FILE)
	sed -i -e's/^Name:.*/Name: $(NAME)/' $(SPEC_FILE)
	mkdir -p $(RPMTOP)/{SPECS,RPMS,SRPMS,SOURCES,BUILD,BUILDROOT}
	cp -f $(SPEC_FILE) $(RPMTOP)/SPECS/
	cp -f  $(TARBALL) $(RPMTOP)/SOURCES/
	rpmbuild -bs --define="_topdir $(RPMTOP)" --define="_sourcedir ." $(SPEC_FILE)

rpm: $(SRPM)
	rpmbuild  --define="_topdir $(RPMTOP)" --rebuild  $<

create_dirs:
	@echo "*** Creating Directories"
	@mkdir -p $(PREFIX)/usr/share/man/man8/
	@mkdir -p $(PREFIX)/usr/bin/

install_image_uploader:
	@echo "*** Deploying image uploader"
	install -D -m 0755 ./src/engine-image-uploader.py $(PREFIX)/usr/share/ovirt-engine/image-uploader/engine-image-uploader.py
	install -D -m 0755 ./src/ovf/__init__.py $(PREFIX)/usr/share/ovirt-engine/image-uploader/ovf/__init__.py
	install -D -m 0755 ./src/ovf/ovfenvelope.py $(PREFIX)/usr/share/ovirt-engine/image-uploader/ovf/ovfenvelope.py
	/usr/bin/gzip -c ./src/engine-image-uploader.8 > $(PREFIX)/usr/share/man/man8/engine-image-uploader.8.gz
	chmod 644 $(PREFIX)/usr/share/man/man8/engine-image-uploader.8.gz
	install -D -m 0600 ./src/imageuploader.conf $(PREFIX)/etc/ovirt-engine/imageuploader.conf
	rm -f $(PREFIX)/usr/bin/engine-image-uploader
	ln -s /usr/share/ovirt-engine/image-uploader/engine-image-uploader.py $(PREFIX)/usr/bin/engine-image-uploader
