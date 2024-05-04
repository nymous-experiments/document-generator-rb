# frozen_string_literal: true

require 'json'

module DocumentGenerator
  module Facture
    INPUT = JSON.parse('{
      "id_facture": "001",
      "date_vente": "2024-04-27",
      "date_emission": "2024-04-27",
      "nom_client": "Client Test",
      "adresse_client": "123 Rue de Test\n59650 Ville Test",
      "items": [
        {
          "nom_item": "Article 1",
          "prix": 10.00,
          "quantite": 2
        },
        {
          "nom_item": "Article 2",
          "prix": 20.00,
          "quantite": 1
        }
      ],
      "date_paiement": "2024-04-27",
      "moyen_paiement": "CB",
      "montant_paiement": 40
    }', symbolize_names: true)

    FOOTER = <<~EOS
      Le délai de paiement est de 45 jours + fin du mois, à partir de la date de facturation.
      En cas de retard de paiement, seront exigibles, conformément à l'article L 441-6 du code de commerce, une indemnité calculée sur la base de trois fois le taux de l'intérêt légal en vigueur ainsi qu'une indemnité forfaitaire pour frais de recouvrement de 40 euros.
    EOS

    CLIENT_INFO = <<~EOS
      Client Test
      123 Rue de Test
      59650 Ville Test
    EOS

    CONDITIONS = <<~EOS
      Conditions de règlement : Prix comptant sans escompte : Chèque (Ordre : Rézoléo), Espèces ou Virement
      Conditions de vente : Prix de départ

      (1) TVA non applicable, article 293 B du CGI
    EOS

    INFO_REZOLEO = <<~EOS
      École Centrale de Lille - Avenue Paul Langevin - 59650 Villeneuve d'Ascq
      rezoleo@rezoleo.fr
      SIRET : 831 134 804 00010
      IBAN : FR76 1670 6050 8753 9414 0728 132
    EOS

    class FactureMetadata
      attr_reader :title
      attr_reader :author
      attr_reader :subject
      attr_reader :creation_date

      def initialize(facture_id:)
        @title = 'Facture Rézoleo'
        @author = 'Association Rézoléo'
        @subject = "Facture #{facture_id}"
        @creation_date = Time.now
      end

      def to_h
        {
          Title: @title,
          Author: @author,
          Subject: @subject,
          CreationDate: @creation_date,
        }
      end
    end

    FactureMetadata2 = Data.define(:Title, :Author, :Subject, :CreationDate) do
      def initialize(facture_id:)
        super(
          Title: 'Facture Rézoléo',
          Author: 'Association Rézoléo',
          Subject: "Facture #{facture_id}",
          CreationDate: Time.now,
        )
      end
    end

    def self.metadata(facture_id:)
      {
        Title: 'Facture Rézoléo',
        Author: 'Association Rézoléo',
        Subject: "Facture #{facture_id}",
        CreationDate: Time.now
      }
    end
  end

end
