# frozen_string_literal: true

require 'prawn'
require 'prawn/measurement_extensions'
require 'prawn/table'

require_relative 'lib/lib'

input = DocumentGenerator::Facture::INPUT
doc_metadata = DocumentGenerator::Facture.metadata(facture_id: input["id_facture"])

pdf = Prawn::Document.new(page_size: 'A4', info: doc_metadata, skip_page_creation: true)

pdf.font_families.update(
  'DejaVu Sans' => {
    normal: 'assets/DejaVuSans.ttf',
    bold: 'assets/DejaVuSans-Bold.ttf'
  }
)
pdf.font_size = 12

pdf.start_new_page
pdf.font('DejaVu Sans')

pdf.repeat(:all) do
  pdf.image 'assets/logo_rezo.png', at: pdf.bounds.top_left, width: 75
  pdf.text 'Facture Rézoléo', style: :bold, size: 14, align: :center

  pdf.float do
    pdf.move_cursor_to 25
    pdf.text DocumentGenerator::Facture::FOOTER, size: 7, align: :center
  end
end

pdf.move_down(2 * pdf.font_size)
pdf.text 'Facture n°001', align: :center
pdf.text 'Date de vente : 2024-04-27', align: :center
pdf.text "Date d'émission : 2024-04-27", align: :center

pdf.move_down(2 * pdf.font_size)
pdf.text 'Association Rézoléo (Trésorerie)', style: :bold

pdf.move_down(1 * pdf.font_size)

pdf.text DocumentGenerator::Facture::INFO_REZOLEO

pdf.move_down(2 * pdf.font_size)

pdf.text 'Client', style: :bold

pdf.move_down(1 * pdf.font_size)

pdf.text <<~EOS
  Client Test
  123 Rue de Test
  59650 Ville Test
EOS

pdf.move_down(3 * pdf.font_size)

items = [
  { nom_item: 'Article 1', prix: 1000, quantite: 2 },
  { nom_item: 'Article 2', prix: 2000, quantite: 1 },
]
data = [
  ['ID', 'Désignation article', 'Prix unit. HT', 'Quantité', 'TVA (1)', 'Total TTC'],
]

items.each_with_index do |item, i|
  item_id = i + 1
  item_name = item[:nom_item]
  price_in_euros = item[:prix] / 100
  quantity = item[:quantite]

  data << [
    item_id.to_s,
    item_name,
    "#{'%.2f' % price_in_euros}€",
    quantity.to_s,
    '0%',
    "#{'%.2f' % (price_in_euros * quantity)}€"
  ]
end

total_price = items.map { |it| it[:prix] * it[:quantite] }.sum / 100
data << [
  { content: 'Total', colspan: 5 },
  "#{'%.2f' % total_price}€",
]

pdf.table(data, header: true, width: pdf.bounds.width, column_widths: { 1 => 200 }) do |t|
  t.row(0).background_color = 'C0C0C0'
end

pdf.move_down(2 * pdf.font_size)

pdf.text "Somme totale hors taxes (en euros, HT) : #{'%.2f' % total_price}€"
pdf.text "Somme totale à payer toutes taxes comprises (en euros, TTC) : #{'%.2f' % total_price}€"

pdf.move_down(1 * pdf.font_size)

pdf.text DocumentGenerator::Facture::CONDITIONS, size: 10, color: '3C3C3C'

pdf.move_down(3 * pdf.font_size)

data = [
  ['Date', 'Règlement', 'Montant', 'À payer'],
  ['2024-04-27', 'CB', '40.00€', '0.00€'],
]

pdf.font_size 10 do
  pdf.table(data) do |t|
    t.row(0).background_color = 'C0C0C0'
  end
end

pdf.render_file 'demo_prawn.pdf'
