# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit db-use eutils eutils git

DESCRIPTION="A P2P network based digital currency."
HOMEPAGE="https://github.com/vinced/namecoin"
EGIT_REPO_URI="https://github.com/vinced/namecoin.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc nls selinux sse2"

DEPEND="dev-libs/boost
	dev-libs/crypto++
	dev-libs/openssl[-bindist]
	nls? (
		sys-devel/gettext
	)
	selinux? (
		sys-libs/libselinux
	)
	sys-libs/db:4.8"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}/trunk"

pkg_setup() {
	ebegin "Creating namecoin user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 /bin/bash /var/lib/namecoin ${PN}
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-Makefile.patch
	# Replace the berkdb cflags with the ones on our system.
	einfo "Berkeley DB: "
	sed -i -e "s:@@GENTOO_DB_INCLUDEDIR@@:$(db_includedir):g" \
		"${S}/makefile.unix"
	# Set the sse2 code
	if use sse2; then
		einfo "Enabling SSE2 code"
		sed -i -e "s:@@GENTOO_CFLAGS_SSE2@@:-DFOURWAYSSE2:g" \
			"${S}/makefile.unix"
		sed -i -e "s:@@GENTOO_SHA256_SSE2@@:-msse2 -O3 -march=amdfam10:g" \
			"${S}/makefile.unix"
	else
		# No sse2 code.
		sed -i -e "s:@@GENTOO_CFLAGS_SSE2@@::g" \
			"${S}/makefile.unix"
		sed -i -e "s:@@GENTOO_SHA256_SSE2@@::g" \
			"${S}/makefile.unix"
	fi
}

src_compile() {
	emake -f makefile.unix namecoind || die "emake namecoind failed";
}

src_install() {
	einfo "Installing daemon"
	dobin namecoind

	einfo "Installing configuration file"
	insinto /etc/namecoin
	newins "${FILESDIR}/namecoin.conf" namecoin.conf
	fowners namecoin:namecoin /etc/namecoin/namecoin.conf
	fperms 600 /etc/namecoin/namecoin.conf

	newconfd "${FILESDIR}/namecoin.confd" namecoind
	# Init script still nonfunctional.
	newinitd "${FILESDIR}/namecoin.initd" namecoind
	dodir /var/lib/namecoin

	einfo "Creating data program directory"
	diropts -m700
	keepdir /var/lib/namecoin
	fperms 700 /var/lib/namecoin
	fowners namecoin:namecoin /var/lib/namecoin/
	dodir /var/lib/namecoin/.namecoin
	fowners namecoin:namecoin /var/lib/namecoin/.namecoin
	dosym /etc/namecoin/namecoin.conf /var/lib/namecoin/.namecoin/namecoin.conf

	if use nls; then
		einfo "Installing language files"
		cd locale
		for val in ${LINGUAS}
		do
			if [ -e "$val/LC_MESSAGES/namecoin.mo" ]; then
				domo "$val/LC_MESSAGES/namecoin.mo" || die "domo $val/LC_MESSAGES/namecoin.mo"
			fi
		done
	fi

	if use doc; then
		einfo "Installing documentation"
		edos2unix *.txt
		dodoc *.txt
	fi
}

#pkg_postinst() {
#	einfo "nothing to post install"
#}

#pkg_postrm() {
#	einfo "nothing to remove"
#}
