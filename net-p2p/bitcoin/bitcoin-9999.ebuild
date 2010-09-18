# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit distutils eutils subversion

DESCRIPTION="A P2P network based digital currency."
HOMEPAGE="http://bitcoin.org/"
ESVN_REPO_URI="https://${PN}.svn.sourceforge.net/svnroot/${PN}/trunk"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+daemon nls wxwidgets"

DEPEND="dev-libs/boost
	dev-libs/openssl
	nls? (
		sys-devel/gettext
	)
	sys-libs/db:4.8
	wxwidgets? (
		app-admin/eselect-wxwidgets
		x11-libs/wxGTK:2.9[X]
	)"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}/trunk"

pkg_setup() {
	ebegin "Creating bitcoin user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 /bin/bash /var/lib/bitcoin ${PN}
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-Makefile.patch
	epatch "${FILESDIR}"/${PN}-bindaddr.patch			# http://www.bitcoin.org/smf/index.php?topic=984.msg13120#msg13120
	epatch "${FILESDIR}"/${PN}-disable_ip_transactions.patch	# http://www.bitcoin.org/smf/index.php?topic=1048.msg13022#msg13022
	epatch "${FILESDIR}"/${PN}-getblock.patch			# http://www.bitcoin.org/smf/index.php?topic=724.msg8053#msg8053
	epatch "${FILESDIR}"/${PN}-listgenerated.patch		# http://www.bitcoin.org/smf/index.php?topic=611.msg11859#msg11859
	epatch "${FILESDIR}"/${PN}-listtransactions.patch		# http://www.bitcoin.org/smf/index.php?topic=611.msg9123#msg9123
	epatch "${FILESDIR}"/${PN}-max_outbound.patch		# http://www.bitcoin.org/smf/index.php?topic=611.msg11859#msg11859
	emake -f makefile.unix
}

src_compile() {
	if use daemon; then
		emake bitcoind || die "emake bitcoind failed";
	fi
	if use wxwidgets; then
		emake bitcoin || die "emake bitcoin failed";
	fi
	if ! use daemon && ! use wxwidgets; then
		einfo "No daemon or wxwidgets USE flag selected, compiling daemon by default."
		emake bitcoind || die "emake bitcoind failed"
	fi
		
}

src_install() {
	if use daemon || ( ! use wxwidgets && ! use daemon ); then
		dobin bitcoind

		insinto /etc/bitcoin
		newins "${FILESDIR}/bitcoin.conf" bitcoin.conf

		newconfd "${FILESDIR}/bitcoin.confd" bitcoind
		# Init script still nonfunctional.
		newinitd "${FILESDIR}/bitcoin.initd" bitcoind
		dodir /var/lib/bitcoin

		keepdir /var/lib/bitcoin
		fperms 700 /var/lib/bitcoin
		fowners bitcoin:bitcoin /var/lib/bitcoin/
		dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf
		fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
	fi
	if use wxwidgets; then
		dobin bitcoin
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
}