# frozen_string_literal: true

require 'hexapdf'

require_relative 'lib/lib'

BASE_FONT_SIZE = 12

# The `InvoiceComposer` class is responsible for creating invoices in PDF format
# using the HexaPDF library. It sets up the document configuration, including
# fonts and styles, and provides methods to add pages with a predefined layout.
# This class is a subclass of `HexaPDF::Composer` and extends its functionality
# to meet the specific requirements of Rezoleo's invoice creation.
class InvoiceComposer < HexaPDF::Composer
  def initialize(skip_page_creation: false, page_size: :A4, page_orientation: :portrait, margin: 36)
    super(skip_page_creation:, page_size:, page_orientation:, margin:)

    # The `pdfa` task ensures that the generated PDF is PDF/A compliant.
    # https://hexapdf.gettalong.org/documentation/pdfa/index.html
    document.task(:pdfa)

    config_font(font_name: 'DejaVu Sans',
                font_file: 'assets/DejaVuSans.ttf',
                bold_font_file: 'assets/DejaVuSans-Bold.ttf')

    config_style(page_size:)
  end

  def config_font(font_name:, font_file:, bold_font_file:)
    document.config['font.map'] = {
      font_name.to_s => {
        none: font_file.to_s,
        bold: bold_font_file.to_s
      }
    }
  end

  def config_style(page_size:)
    style(:base, font: 'DejaVu Sans', font_size: BASE_FONT_SIZE, line_spacing: 1.2)
    style(:bold, font: ['DejaVu Sans', { variant: :bold }])
    style(:header, font: ['DejaVu Sans', { variant: :bold }], font_size: BASE_FONT_SIZE * 7 / 6, text_align: :center)
    style(:footer, font_size: BASE_FONT_SIZE / 2, text_align: :center)
    style(:table_header, font: 'DejaVu Sans', font_size: BASE_FONT_SIZE * 0.75)
    style(:conditions, font_size: BASE_FONT_SIZE * 5 / 6, fill_color: '3C3C3C')

    page_style(:default, page_size:)
  end

  def new_page(style = @next_page_style)
    super(style)

    image('assets/logo_rezo.png', width: 75, position: :float, mask_mode: :none)
    text('Facture Rézoléo', style: :header, margin: margin_bottom(2))

    text(DocumentGenerator::Invoice::FOOTER, style: :footer, position: [0, 0])
  end
end

def margin_bottom(lines)
  [0, 0, lines * BASE_FONT_SIZE]
end

def format_cents(cents)
  # float conversion to avoid integer division causing rounding errors
  "#{format('%.2f', cents.to_f / 100)}€"
end

input = DocumentGenerator::Invoice::INPUT
doc_metadata = DocumentGenerator::Invoice::PDFMetadata.new(invoice_id: input[:invoice_id])

composer = InvoiceComposer.new(skip_page_creation: true)

# composer.document.config['debug'] = true

composer.document.metadata.title(doc_metadata.title)
composer.document.metadata.author(doc_metadata.author)
composer.document.metadata.subject(doc_metadata.subject)
composer.document.metadata.creation_date(doc_metadata.creation_date)

composer.new_page

invoice_header = <<~HEADER
  Facture n°#{input[:invoice_id]}
  Date de vente : #{input[:sale_date]}
  Date d'émission : #{input[:issue_date]}
HEADER

composer.text(invoice_header, style: :base, text_align: :center, margin: margin_bottom(2))

composer.text('Association Rézoléo (Trésorerie)', style: :bold, margin: margin_bottom(1))

composer.text(DocumentGenerator::Invoice::INFO_REZOLEO, margin: margin_bottom(2))

composer.text('Client', style: :bold, margin: margin_bottom(1))

composer.text(input[:client_name], margin: margin_bottom(1))
composer.text(input[:client_address], margin: margin_bottom(3))

header = lambda do |_tb|
  [
    { background_color: 'C0C0C0' },
    [
      composer.document.layout.text('ID', style: :table_header),
      composer.document.layout.text('Désignation article', style: :table_header),
      composer.document.layout.text('Prix unit. HT', style: :table_header, text_align: :right),
      composer.document.layout.text('Quantité', style: :table_header, text_align: :right),
      composer.document.layout.text('TVA (1)', style: :table_header, text_align: :right),
      composer.document.layout.text('Total TTC', style: :table_header, text_align: :right),
    ]
  ]
end

data = []
items = input[:items]

items.each_with_index do |item, i|
  item_id = i + 1
  item_name = item[:item_name]
  price_in_cents = item[:price_cents]
  quantity = item[:quantity]

  data << [
    item_id.to_s,
    item_name,
    composer.document.layout.text(format_cents(price_in_cents), text_align: :right),
    composer.document.layout.text(quantity.to_s, text_align: :right),
    composer.document.layout.text('0%', text_align: :right),
    composer.document.layout.text(format_cents(price_in_cents * quantity), text_align: :right)
  ]
end

total_price_in_cents = items.map { |it| it[:price_cents] * it[:quantity] }.sum

data << [
  { content: 'Total', col_span: 5 },
  composer.document.layout.text(format_cents(total_price_in_cents), text_align: :right)
]

composer.table(data, column_widths: [-1, -9, -3, -2, -2, -3], header:, margin: margin_bottom(2))

composer.text("Somme totale hors taxes (en euros, HT) : #{format_cents(total_price_in_cents)}")
composer.text("Somme totale à payer toutes taxes comprises (en euros, TTC) : #{format_cents(total_price_in_cents)}",
              margin: margin_bottom(1))

composer.text(DocumentGenerator::Invoice::CONDITIONS, style: :conditions, margin: margin_bottom(3))

header = lambda do |_tb|
  [
    { background_color: 'C0C0C0' },
    [
      composer.document.layout.text('Date', style: :table_header),
      composer.document.layout.text('Règlement', style: :table_header),
      composer.document.layout.text('Montant', style: :table_header, text_align: :right),
      composer.document.layout.text('À payer', style: :table_header, text_align: :right)
    ]
  ]
end

payed_in_cents = input[:payment_amount_cents] || 0
left_to_pay_in_cents = total_price_in_cents - payed_in_cents

payment_method = input[:payment_method] || ''

data = [[
  composer.document.layout.text(input[:payment_date], style: :table_header),
  composer.document.layout.text(payment_method, style: :table_header),
  composer.document.layout.text(format_cents(payed_in_cents), style: :table_header, text_align: :right),
  composer.document.layout.text(format_cents(left_to_pay_in_cents), style: :table_header, text_align: :right)
]]

composer.table(data, column_widths: [-3, -5, -2, -2], header:, width: 300)

composer.write('demo_hexa.pdf')
