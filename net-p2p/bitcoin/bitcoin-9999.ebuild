# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit db-use distutils eutils subversion wxwidgets

DESCRIPTION="A P2P network based digital currency."
HOMEPAGE="http://bitcoin.org/"
ESVN_REPO_URI="https://${PN}.svn.sourceforge.net/svnroot/${PN}/trunk"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="daemon doc nls selinux sse2 wxwidgets"

DEPEND="dev-libs/boost
	dev-libs/crypto++
	dev-libs/openssl
	nls? (
		sys-devel/gettext
	)
	selinux? (
		sys-libs/libselinux
	)
	sys-libs/db:4.8
	wxwidgets? (
		app-admin/eselect-wxwidgets
		x11-libs/wxGTK:2.9[X]
	)"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}/trunk"

pkg_setup() {
	if use daemon; then
		ebegin "Creating bitcoin user and group"
		enewgroup ${PN}
		enewuser ${PN} -1 /bin/bash /var/lib/bitcoin ${PN}
	fi;
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

	# http://www.bitcoin.org/smf/index.php?topic=1319.0
	epatch "${FILESDIR}"/${PN}-monitor.patch
	# http://www.bitcoin.org/smf/index.php?topic=984.msg13120#msg13120
	#epatch "${FILESDIR}"/${PN}-bindaddr.patch
	# http://www.bitcoin.org/smf/index.php?topic=1048.msg13022#msg13022
	epatch "${FILESDIR}"/${PN}-disable_ip_transactions.patch
	# http://www.bitcoin.org/smf/index.php?topic=611.msg11859#msg11859
	epatch "${FILESDIR}"/${PN}-listgenerated.patch
	# http://www.bitcoin.org/smf/index.php?topic=611.msg9123#msg9123
	epatch "${FILESDIR}"/${PN}-listtransactions.patch
	# http://www.bitcoin.org/smf/index.php?topic=611.msg11859#msg11859
	epatch "${FILESDIR}"/${PN}-max_outbound.patch
}

src_compile() {
	if use daemon; then
		emake -f makefile.unix bitcoind || die "emake bitcoind failed";
	fi
	if use wxwidgets; then
		emake -f makefile.unix bitcoin || die "emake bitcoin failed";
	fi
	if ! use daemon && ! use wxwidgets; then
		einfo "No daemon or wxwidgets USE flag selected, compiling daemon by default."
		emake -f makefile.unix 																																																							bitcoind || die "emake bitcoind failed"
	fi
}

src_install() {
	if use daemon || ( ! use wxwidgets && ! use daemon ); then
		einfo "Installing daemon"
		dobin bitcoind

		einfo "Installing configuration file"
		insinto /etc/bitcoin
		newins "${FILESDIR}/bitcoin.conf" bitcoin.conf
		fowners bitcoin:bitcoin /etc/bitcoin/bitcoin.conf
		fperms 600 /etc/bitcoin/bitcoin.conf

		newconfd "${FILESDIR}/bitcoin.confd" bitcoind
		# Init script still nonfunctional.
		newinitd "${FILESDIR}/bitcoin.initd" bitcoind
		dodir /var/lib/bitcoin

		einfo "Creating data program directory"
		diropts -m700
		keepdir /var/lib/bitcoin
		fperms 700 /var/lib/bitcoin
		fowners bitcoin:bitcoin /var/lib/bitcoin/
		dodir /var/lib/bitcoin/.bitcoin
		fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
		dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf
	fi
	if use wxwidgets; then
		einfo "Installing wxwidgets gui"
		dobin bitcoin
		insinto /usr/share/pixmaps
		doins "${S}/rc/bitcoin.ico"
		make_desktop_entry ${PN} "Bitcoin" "/usr/share/pixmaps/bitcoin.ico" "Network;P2P"
	fi
	if use nls; then
		einfo "Installing language files"
		cd locale
		for val in ${LINGUAS}
		do
			if [ -e "$val/LC_MESSAGES/bitcoin.mo" ]; then
				domo "$val/LC_MESSAGES/bitcoin.mo" || die "domo $val/LC_MESSAGES/bitcoin.mo"
			fi
		done
	fi
	
	if use doc; then
		einfo "Installing documentation"
		edos2unix *.txt
		dodoc *.txt
	fi
}