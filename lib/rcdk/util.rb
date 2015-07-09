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
jrequire 'org.openscience.cdk.interfaces.IAtomContainer'
jrequire 'org.openscience.cdk.interfaces.IAtomContainerSet'
jrequire 'org.openscience.cdk.layout.StructureDiagramGenerator'
jrequire 'org.openscience.cdk.graph.ConnectivityChecker'
jrequire 'org.openscience.cdk.templates.MoleculeFactory'
jrequire 'org.openscience.cdk.AtomContainer'
jrequire 'org.openscience.cdk.AtomContainerSet'

jrequire 'org.openscience.cdk.geometry.GeometryTools'

jrequire 'org.openscience.cdk.tools.manipulator.AtomContainerManipulator'

jrequire 'java.util.List'
jrequire 'java.util.ArrayList'

jrequire 'java.awt.Rectangle'
jrequire 'java.awt.image.BufferedImage'
jrequire 'java.awt.Color'
jrequire 'javax.imageio.ImageIO'
jrequire 'javax.vecmath.Vector2d'
jrequire 'java.awt.geom.Rectangle2D'

jrequire 'org.openscience.cdk.renderer.font.AWTFontManager'
jrequire 'org.openscience.cdk.renderer.generators.BasicSceneGenerator'

jrequire 'org.openscience.cdk.renderer.generators.BasicBondGenerator'
jrequire 'org.openscience.cdk.renderer.generators.BasicAtomGenerator'
jrequire 'org.openscience.cdk.renderer.AtomContainerRenderer'
jrequire 'org.openscience.cdk.renderer.MoleculeSetRenderer'
jrequire 'org.openscience.cdk.renderer.RendererModel'
jrequire 'org.openscience.cdk.renderer.visitor.AWTDrawVisitor'
jrequire 'org.openscience.cdk.renderer.BoundsCalculator'
jrequire 'org.openscience.cdk.silent.SilentChemObjectBuilder'


# The Ruby Chemistry Development Kit.
module RCDK

  # Convenience methods for working with the CDK.
  module Util

    # Molecular language translation. Currently molfile, SMILES,
    # and IUPAC nomenclature (read-only) are implemented.
    class Lang
      include Org::Openscience::Cdk
      include Org::Openscience::Cdk::Silent
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
      include Org::Openscience::Cdk::Graph
      include Org::Openscience::Cdk::Templates
      include Org::Openscience::Cdk::Tools::Manipulator
      include Javax::Vecmath
      include Java::Awt::Geom
      @@sdg = Layout::StructureDiagramGenerator.new

      # Assigns 2-D coordinates to the indicated CDK <tt>molecule</tt>.
      def self.coordinate_molecule(molecule)
        if ConnectivityChecker.isConnected(molecule)
          @@sdg.setMolecule(molecule, false)
          @@sdg.generateCoordinates()
          @@sdg.getMolecule
        else
          moleculeSet = ConnectivityChecker.partitionIntoMolecules(molecule)
          double_class = Rjb::import("java.awt.geom.Rectangle2D$Double")
          origin_rect = double_class.new(0, 0, 0, 0)
          hoffset = origin_rect.getHeight()/2.0
          translated_rect = double_class.new(0, 0, 0, 0)

          molecules = AtomContainerSet.new
          container_count = moleculeSet.getAtomContainerCount()
          (0..container_count-1).to_a.each do |c|
            mol = moleculeSet.getAtomContainer(c)
            #add Hydrogens only when the molecule has no bond
            AtomContainerManipulator.convertImplicitToExplicitHydrogens(mol) unless mol.bonds.iterator.hasNext
            @@sdg.setMolecule(mol, false)
            @@sdg.generateCoordinates()
            new_mol = translate_molecule(@@sdg.getMolecule, origin_rect, translated_rect, hoffset)
            molecules.addAtomContainer(new_mol)
          end
          molecules
        end

      end

      def self.translate_molecule(molecule, origin_rect, translated_rect, hoffset)
        mol_rect = Geometry::GeometryTools.getRectangle2D(molecule)
        origin_rect.setRect(origin_rect.getX(), origin_rect.getY(), 1 + origin_rect.getWidth() + (mol_rect.getWidth()==0 ? 1.5 : mol_rect.getWidth()), mol_rect.getHeight()> origin_rect.getHeight() ? mol_rect.getHeight() : origin_rect.getHeight())
        mol_rect = Geometry::GeometryTools.getRectangle2D(molecule)
        Geometry::GeometryTools.translate2D(molecule, -mol_rect.getX() + translated_rect.getX() + translated_rect.getWidth(), -mol_rect.getY() + translated_rect.getY() + hoffset - (mol_rect.getHeight()/2.0))
        translated_rect.setRect(translated_rect.getX(), translated_rect.getY(), 1 + translated_rect.getWidth() + (mol_rect.getWidth()==0 ? 1.5 : mol_rect.getWidth()), mol_rect.getHeight()> translated_rect.getHeight() ? mol_rect.getHeight() : translated_rect.getHeight())
        molecule
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
        bond_generator = BasicBondGenerator.new
        bond_generator.setOverrideBondWidth(0.2)
        generators.add(BasicSceneGenerator.new)
        generators.add(bond_generator)
        generators.add(BasicAtomGenerator.new)
        renderer_class = molecule._classname == "org.openscience.cdk.AtomContainerSet" ? MoleculeSetRenderer : AtomContainerRenderer
        renderer = renderer_class.new(generators, AWTFontManager.new)
        renderer.setup(molecule, drawArea)
        #model = renderer.getRenderer2DModel()
        #model.set(BasicBondGenerator.BondWidth.class, 5.0)

        diagram = renderer.calculateDiagramBounds(molecule)
        renderer.setZoomToFit(drawArea.width, drawArea.height, diagram.width, diagram.height)

        g2 = image.getGraphics()
        g2.setColor(Color.WHITE)
        g2.fillRect(0, 0, width, height)
        renderer.paintMolecule(molecule, AWTDrawVisitor.new(g2))

        ImageIO.write(image, "PNG", Rjb::import('java.io.File').new(path_to_png))
      end

      def self.writeJPG(molecule, width, height, path_to_jpg)
        drawArea = Rectangle.new(width, height)
        image = BufferedImage.new(width, height, BufferedImage.TYPE_INT_RGB)
        generators = ArrayList.new
        bond_generator = BasicBondGenerator.new
        bond_generator.setOverrideBondWidth(1)
        generators.add(BasicSceneGenerator.new)
        generators.add(bond_generator)
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
