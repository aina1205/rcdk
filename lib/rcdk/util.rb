# =============================================
# RCDK - The Chemistry Development Kit for Ruby
# =============================================
#
# Project Info: http://rubyforge.org/projects/rcdk
# Blog: http://depth-first.com
#
# Copyright (C) 2006 Richard L. Apodaca
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software
# Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor
# Boston, MA 02111-1301, USA.

require 'rcdk'


jrequire 'org.openscience.cdk.smiles.SmilesParser'
jrequire 'org.openscience.cdk.smiles.SmilesGenerator'
jrequire 'org.openscience.cdk.DefaultChemObjectBuilder'
jrequire 'org.openscience.cdk.Molecule'
jrequire 'org.openscience.cdk.layout.StructureDiagramGenerator'



jrequire 'java.util.List'
jrequire 'java.util.ArrayList'

jrequire 'java.awt.Rectangle'
jrequire 'java.awt.image.BufferedImage'
jrequire 'java.awt.Color'
jrequire 'javax.imageio.ImageIO'

jrequire 'org.openscience.cdk.renderer.font.AWTFontManager'
jrequire 'org.openscience.cdk.renderer.generators.BasicSceneGenerator'

jrequire 'org.openscience.cdk.renderer.generators.BasicBondGenerator'
jrequire 'org.openscience.cdk.renderer.generators.BasicAtomGenerator'
jrequire 'org.openscience.cdk.renderer.AtomContainerRenderer'
jrequire 'org.openscience.cdk.renderer.RendererModel'
jrequire 'org.openscience.cdk.renderer.visitor.AWTDrawVisitor'
jrequire 'org.openscience.cdk.silent.SilentChemObjectBuilder'



# The Ruby Chemistry Development Kit.
module RCDK

  # Convenience methods for working with the CDK.
  module Util

    # Molecular language translation. Currently molfile, SMILES,
    # and IUPAC nomenclature (read-only) are implemented.
    class Lang
      include Org::Openscience::Cdk
      #include Org::Openscience::Cdk::Io
      include Org::Openscience::Cdk::Silent
      #include Java::Io

      @@smiles_parser = Smiles::SmilesParser.new(SilentChemObjectBuilder.getInstance())
      #@@smiles_generator = Smiles::SmilesGenerator.new(DefaultChemObjectBuilder.getInstance)
      # Returns a CDK <tt>Molecule</tt> by parsing <tt>smiles</tt>.
      def self.read_smiles(smiles)
        @@smiles_parser.parseSmiles(smiles)
      end
    end
    # 2-D coordinate generation.
    class XY
      include Org::Openscience::Cdk

      @@sdg = Layout::StructureDiagramGenerator.new

      # Assigns 2-D coordinates to the indicated CDK <tt>molecule</tt>.
      def self.coordinate_molecule(molecule)
        @@sdg.setMolecule(molecule)
        @@sdg.generateCoordinates
        @@sdg.getMolecule
      end
    end

    # Raster and SVG 2-D molecular images.
    class Image

      include Org::Openscience::Cdk
      #include Org::Openscience::Cdk::Io
      include Org::Openscience::Cdk::Silent
      include Org::Openscience::Cdk::Renderer::Generators
      include Org::Openscience::Cdk::Renderer
      include Org::Openscience::Cdk::Renderer::Font
      include Org::Openscience::Cdk::Renderer::Visitor
      #include Java::Io
      include Java::Awt
      include Java::Awt::Image
      include Javax::Imageio
      include Java::Util

      def self.writePNG(molecule, width, height, path_to_png)
        drawArea = Rectangle.new(width, height)
        image = BufferedImage.new(width, height, BufferedImage.TYPE_INT_RGB)
        generators = ArrayList.new
        generators.add(BasicSceneGenerator.new)
        generators.add(BasicBondGenerator.new)
        generators.add(BasicAtomGenerator.new)
        renderer = AtomContainerRenderer.new(generators, AWTFontManager.new)
        renderer.setup(molecule, drawArea)
        #model = renderer.getRenderer2DModel()
        #model.set(@@zoom_factor.class, 0.9)
        #model.set(BasicBondGenerator.BondWidth.class, 5.0)
        #model.set(BasicSceneGenerator.ZoomFactor.class, 0.9)
        #model.setZoomFactor(2)
        #model.setBondWidth(2)
        #model.setAtomRadius(5)
        #renderer.setZoom(0.9)
        diagram = renderer.calculateDiagramBounds(molecule)
        renderer.setZoomToFit(drawArea.width, drawArea.height, diagram.width, diagram.height)

        g2 = image.getGraphics()
        g2.setColor(Color.WHITE)
        g2.fillRect(0, 0, width, height)
        renderer.paint(molecule, AWTDrawVisitor.new(g2))

        ImageIO.write(image, "PNG", Rjb::import('java.io.File').new(path_to_png))
      end

      def self.writeJPG(molecule, width, height, path_to_jpg)
        drawArea = Rectangle.new(width, height)
        image = BufferedImage.new(width, height, BufferedImage.TYPE_INT_RGB)
        generators = ArrayList.new
        generators.add(BasicSceneGenerator.new)
        generators.add(BasicBondGenerator.new)
        generators.add(BasicAtomGenerator.new)
        renderer = AtomContainerRenderer.new(generators, AWTFontManager.new)
        renderer.setup(molecule, drawArea)
        diagram = renderer.calculateDiagramBounds(molecule)
        renderer.setZoomToFit(drawArea.width, drawArea.height, diagram.width, diagram.height)

        g2 = image.getGraphics()
        g2.setColor(Color.WHITE)
        g2.fillRect(0, 0, width, height)
        renderer.paint(molecule, AWTDrawVisitor.new(g2))
        ImageIO.write(image, "jpg", Rjb::import('java.io.File').new(path_to_jpg))
      end

      # Writes a <tt>width</tt> by <tt>height</tt> PNG image to
      # <tt>path_to_png</tt> using <tt>smiles</tt>. Coordinates are automatically
      # assigned.
      def self.smiles_to_png(smiles, path_to_png, width, height)
        mol = XY.coordinate_molecule(Lang.read_smiles(smiles))

        self.writePNG(mol, width, height, path_to_png)
      end


      # Writes a <tt>width</tt> by <tt>height</tt> JPG image to
      # <tt>path_to_jpg</tt> using <tt>smiles</tt>. Coordinates are automatically
      # assigned.
      def self.smiles_to_jpg(smiles, path_to_jpg, width, height)
        mol = XY.coordinate_molecule(Lang.read_smiles(smiles))

        self.writeJPG(mol, width, height, path_to_jpg)
      end


    end
  end
end