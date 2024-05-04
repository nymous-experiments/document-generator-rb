# frozen_string_literal: true

require 'hexapdf'

require_relative 'lib/lib'

BASE_FONT_SIZE = 12

class FactureComposer < HexaPDF::Composer
  def initialize(skip_page_creation: false, page_size: :A4, page_orientation: :portrait,
                 margin: 36)
    super(skip_page_creation:, page_size:, page_orientation:, margin:)

    # https://hexapdf.gettalong.org/documentation/pdfa/index.html
    document.task(:pdfa)

    document.config['font.map'] = {
      'DejaVu Sans' => {
        none: 'assets/DejaVuSans.ttf',
        bold: 'assets/DejaVuSans-Bold.ttf',
      }
    }
    style(:base, font: 'DejaVu Sans', font_size: BASE_FONT_SIZE, line_spacing: 1.2)
    style(:bold, font: ['DejaVu Sans', { variant: :bold }])
    style(:header, font: ['DejaVu Sans', { variant: :bold }], font_size: BASE_FONT_SIZE * 7 / 6, text_align: :center) # TODO: Use 14 as hardcoded?
    style(:footer, font_size: 7, text_align: :center) # TODO: Use `BASE_FONT_SIZE / 2`?

    page_style(:default, page_size: page_size) do |canvas, style|
      # canvas.font('DejaVu Sans', size: 12)
      # canvas.text("Coucou", at: [50, 50], position: :flow)
      margins = HexaPDF::Layout::Style::Quad.new(0)
      # margins.top =
      # style.frame = style.create_frame(canvas.context, margins)
    end
  end

  def new_page(style = @next_page_style)
    super(style)

    image('assets/logo_rezo.png', width: 75, position: :float, mask_mode: :none)
    text('Facture Rézoléo', style: :header, margin: margin_bottom(2))

    text(DocumentGenerator::Facture::FOOTER, style: :footer, position: [0, 0], text_align: :center)
  end
end

def margin_bottom(lines)
  [0, 0, lines * BASE_FONT_SIZE]
end

input = DocumentGenerator::Facture::INPUT
doc_metadata = DocumentGenerator::Facture::FactureMetadata.new(facture_id: input[:id_facture])

composer = FactureComposer.new(skip_page_creation: true)

# composer.document.config['debug'] = true

composer.document.metadata.title(doc_metadata.title)
composer.document.metadata.author(doc_metadata.author)
composer.document.metadata.subject(doc_metadata.subject)
composer.document.metadata.creation_date(doc_metadata.creation_date)

composer.new_page

facture_header = <<~EOS
Facture n°001
Date de vente : 2024-04-27
Date d'émission : 2024-04-27
EOS
composer.text(facture_header, text_align: :center, margin: margin_bottom(2))

composer.text('Association Rézoléo (Trésorerie)', style: :bold, margin: margin_bottom(1))

composer.text(DocumentGenerator::Facture::INFO_REZOLEO, margin: margin_bottom(2))

composer.text('Client', style: :bold, margin: margin_bottom(1))

composer.text(DocumentGenerator::Facture::CLIENT_INFO, margin: margin_bottom(3))

items = [
  { nom_item: 'Article 1', prix: 1000, quantite: 2 },
  { nom_item: 'Article 2', prix: 2000, quantite: 1 },
]

header = lambda do |tb|
  [
    { background_color: 'C0C0C0' },
    [
      # TODO: Fix this once HexaPDF header supports passing only strings, like for data
      composer.document.layout.text('ID'),
      composer.document.layout.text('Désignation article'),
      composer.document.layout.text('Prix unit. HT', text_align: :right),
      composer.document.layout.text('Quantité', text_align: :right),
      composer.document.layout.text('TVA (1)', text_align: :right),
      composer.document.layout.text('Total TTC', text_align: :right),
    ]
  ]
end
data = []

items.each_with_index do |item, i|
  item_id = i + 1
  item_name = item[:nom_item]
  price_in_euros = item[:prix] / 100
  quantity = item[:quantite]

  data << [
    item_id.to_s,
    item_name,
    composer.document.layout.text("#{'%.2f' % price_in_euros}€", text_align: :right),
    composer.document.layout.text(quantity.to_s, text_align: :right),
    composer.document.layout.text('0%', text_align: :right),
    composer.document.layout.text("#{'%.2f' % (price_in_euros * quantity)}€", text_align: :right),
  ]
end

total_price = items.map { |it| it[:prix] * it[:quantite] }.sum / 100
data << [
  { content: 'Total', col_span: 5 },
  composer.document.layout.text("#{'%.2f' % total_price}€", text_align: :right),
]

composer.table(data, column_widths: [-2, -8, -5, -4, -4, -4], header: header, margin: margin_bottom(2))

composer.text("Somme totale hors taxes (en euros, HT) : #{'%.2f' % total_price}€")
composer.text("Somme totale à payer toutes taxes comprises (en euros, TTC) : #{'%.2f' % total_price}€", margin: margin_bottom(1))

composer.text DocumentGenerator::Facture::CONDITIONS, font_size: 10, fill_color: '3C3C3C', margin: margin_bottom(3)

header = lambda do |tb|
  [
    { background_color: 'C0C0C0', font_size: 10 },
    [
      # TODO: Fix this once HexaPDF header supports passing only strings, like for data
      composer.document.layout.text('Date'),
      composer.document.layout.text('Règlement'),
      composer.document.layout.text('Montant', text_align: :right),
      composer.document.layout.text('À payer', text_align: :right),
    ]
  ]
end

data = [
  { font_size: 10 },
  [
    '2024-04-27',
    'CB',
    composer.document.layout.text('40.00€', text_align: :right),
    composer.document.layout.text('0.00€', text_align: :right)
  ]
]

composer.table(data, header: header, width: 400)

# composer.document.pages.each do |page|
#   box = page.canvas.context.box(:media)
#   page.canvas.font('DejaVu Sans', size: 12)
# end

composer.write('demo_hexa.pdf')
