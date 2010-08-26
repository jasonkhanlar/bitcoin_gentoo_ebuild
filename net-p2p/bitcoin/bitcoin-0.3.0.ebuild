# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-mobilephone/lightblue/lightblue-0.4.ebuild,v 1.3 2010/03/27 17:57:36 arfrever Exp $

EAPI="2"

inherit distutils

DESCRIPTION="LightBlue is a cross-platform Bluetooth API for Python which provides simple access to Bluetooth operations"
HOMEPAGE="http://bitcoin.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="dev-libs/boost
	dev-libs/openssl
	sys-libs/db
	x11-libs/gtk+:2"

RDEPEND="${DEPEND}"

src_prepare() {
	cd src
	
	sed -i \
		-e "s:-I\"/usr/local/include/wx-2.9\":-I\"/usr/local/include/wx-2.9\" -I\"/usr/include/wx-2.8\" -I\"/usr/lib64/wx/include/gtk2-unicode-release-2.8/\" -I\"/usr/include/db4.7/\":" \
		makefile.unix \
		|| die "sed bitcoin failed"
	make -f makefile.unix
	#make -f makefile.unix bitcoind
}

src_install() {
	cd src
}