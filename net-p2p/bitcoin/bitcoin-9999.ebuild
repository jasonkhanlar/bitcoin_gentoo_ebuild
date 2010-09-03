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
KEYWORDS="~x86"
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
	enewuser ${PN} -1 -1 /var/lib/bitcoin ${PN}
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-Makefile.patch
	epatch "${FILESDIR}"/${PN}-getblock.patch			# http://www.bitcoin.org/smf/index.php?topic=724.msg8053#msg8053
	epatch "${FILESDIR}"/${PN}-http-json-rpc-bind-any.patch	# http://www.bitcoin.org/smf/index.php?topic=611.msg11859#msg11859
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
		# Install default configuration - Currently unused due to nonfunctional init script
		insinto /etc/bitcoin
		newins "${FILESDIR}/bitcoin.conf" bitcoin.conf

		# Currently init script will not work due to ~/.bitcoin evaluated as /root/.bitcoin as user ${BITCOIN_USER}
		# As soon as discovery of method to store all bitcoin files into /etc/bitcoin/ the init script will work.
		#newconfd "${FILESDIR}/bitcoin.confd" bitcoin
		#newinitd "${FILESDIR}/bitcoin.initd" bitcoin
		dodir /var/lib/bitcoin

		# We need the symlink to su to bitcoind to stop it.
		dodir /var/lib/bitcoin/.bitcoin
		dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf
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