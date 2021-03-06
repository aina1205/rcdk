=RCDK - The Ruby Interface for the Chemistry Development Kit (CDK)
RCDK makes it possible to use the Chemistry Development Kit (CDK)
from Ruby. CDK is a Java library for chemical informatics.
==Typical Usage
require 'rubygems'
require_gem 'rcdk'
require 'rcdk/util'
mol = RCDK::Util::Lang.read_smiles 'c1ccccc1'
puts mol.getAtomCount # =>6
==Downloading
Both a RubyGems installation package and a full source package
can be obtained from:
http://rubyforge.org/projects/rcdk
==Requirements
RCDK was developed with Ruby 1.8.4. Earlier versions of Ruby
may also be compatible. Ruby Java Bridge is used to interface
to the Java Virtual Machine.
==Installing
The RubyGems package can be installed using the following command
(as root):
gem install rcdk
This command will optionally install Ruby Java Bridge, if it
hasn't been installed yet.
==License
RCDK is distributed under the GNU LGPL version 2.1 (see 'LICENSE').
It contains bytecode from the following sources:
-Chemistry Development Kit (CDK), licensed under the LGPL: http://cdk.sf.net
-OPSIN, licensed under the Artistic License: http://sourceforge.net/projects/oscar3-chem/
-Structure-CDK, licensed under the LGPL: http://sf.net/projects/structure
