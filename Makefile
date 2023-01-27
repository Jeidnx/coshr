DESTDIR = /

install: coshr.sh template.html
	install -Dm 755 coshr.sh ${DESTDIR}usr/bin/coshr
	install -Dm 444 template.html ${DESTDIR}usr/share/doc/coshr/template.html