# frozen_string_literal: true

require 'json'

module DocumentGenerator
  module Invoice
    INPUT = JSON.parse('{
      "invoice_id": "001",
      "sale_date": "2024-04-27",
      "issue_date": "2024-04-27",
      "client_name": "Client Test",
      "client_address": "123 Test Street\n59650 Test City",
      "items": [
        {
          "item_name": "Item 1",
          "price_cents": 1000,
          "quantity": 2
        },
        {
          "item_name": "Item 2",
          "price_cents": 2000,
          "quantity": 1
        }
      ],
      "payment_date": "2024-04-27",
      "payment_method": "Carte Bancaire",
      "payment_amount_cents": 40
    }', symbolize_names: true)

    FOOTER = <<~FOOTER
      Le délai de paiement est de 45 jours + fin du mois, à partir de la date de facturation (date d'émission de la facture).
      En cas de retard de paiement, seront exigibles, conformément à l'article L 441-6 du code de commerce, une indemnité calculée sur la base de trois fois le taux de l'intérêt légal en vigueur ainsi qu'une indemnité forfaitaire pour frais de recouvrement de 40 euros.
    FOOTER

    CONDITIONS = <<~CONDITIONS
      Conditions de règlement : Prix comptant sans escompte
      Moyen de paiement : Chèque (ordre : Rézoléo), Espèces ou Virement
      Conditions de vente : Prix de départ

      (1) TVA non applicable, article 293 B du CGI
    CONDITIONS

    INFO_REZOLEO = <<~INFOS
      École Centrale de Lille - Avenue Paul Langevin - 59650 Villeneuve d'Ascq
      rezoleo@rezoleo.fr
      SIRET : 831 134 804 00010
      IBAN : FR76 1670 6050 8753 9414 0728 132
    INFOS

    PDFMetadata = Data.define(:title, :author, :subject, :creation_date) do
      def initialize(invoice_id:)
        super(
          title: "Facture Rézoléo #{invoice_id}",
          author: 'Association Rézoléo',
          subject: "Facture #{invoice_id}",
          creation_date: Time.now
        )
      end
    end
  end
end
