DESTDIR = /

install: coshr.sh template.html
	install -d ${DESTDIR}usr/bin
	install -m 755 coshr.sh ${DESTDIR}usr/bin/coshr
	install -d ${DESTDIR}usr/share/doc/coshr/
	install -m 444 template.html ${DESTDIR}usr/share/doc/coshr/template.html