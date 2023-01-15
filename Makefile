install: coshr.sh template.html
	mkdir -p /usr/bin/
	mkdir -p /usr/share/doc/coshr/
	install -Dm 755 coshr.sh /usr/bin/coshr
	install -Dm 644 template.html /usr/share/doc/coshr/template.html