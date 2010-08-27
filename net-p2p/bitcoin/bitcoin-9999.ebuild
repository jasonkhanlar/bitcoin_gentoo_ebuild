# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-mobilephone/lightblue/lightblue-0.4.ebuild,v 1.3 2010/03/27 17:57:36 arfrever Exp $

EAPI="2"

inherit distutils eutils subversion

DESCRIPTION="Bitcoin is a peer-to-peer network based digital currency.  Peer-to-peer (P2P) means that there is no central authority to issue new money or keep track of transactions. Instead, these tasks are managed collectively by the nodes of the network."
HOMEPAGE="http://bitcoin.org"
ESVN_REPO_URI="https://bitcoin.svn.sourceforge.net/svnroot/${PN}"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND="dev-libs/openssl
	dev-libs/boost
	sys-libs/db:4.8
	x11-libs/wxGTK:2.9"
RDEPEND="${DEPEND}"

pkg_setup() {
	ebegin "Creating bitcoin user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 /home/bitcoin ${PN}
}

src_prepare() {
	cd trunk
	epatch "${FILESDIR}"/${P}-Makefile.patch
	epatch "${FILESDIR}"/${P}-getblock.patch		# http://www.bitcoin.org/smf/index.php?topic=724.msg8053#msg8053
	epatch "${FILESDIR}"/${P}-listtransactions.patch	# http://www.bitcoin.org/smf/index.php?topic=611.msg9123#msg9123
	make -f makefile.unix
}

src_compile() {
	cd trunk
	emake
}

src_install() {
	cd trunk
	dobin bitcoin
	dobin bitcoind
	
	# Install default configuration - Currently unused due to nonfunctional init script
        insinto /etc/bitcoin
	newins "${FILESDIR}/bitcoin.conf" bitcoin.conf

	# Currently init script will not work due to ~/.bitcoin evaluated as /root/.bitcoin as user ${BITCOIN_USER}
	# As soon as discovery of method to store all bitcoin files into /etc/bitcoin/ the init script will work.
	#newconfd "${FILESDIR}/bitcoin.confd" bitcoin
	#newinitd "${FILESDIR}/bitcoin.initd" bitcoin
}