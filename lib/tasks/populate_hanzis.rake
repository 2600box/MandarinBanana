# -*- coding: utf-8 -*-
namespace :db do
  desc "Feed database with Hanzis"
  task populate_hanzis: :environment do
    hanzis = File.open('lib/assets/prepared-hanzis.csv').read
    hanzis.each_line do |line|
      hanzi = line.split("\t")[0]
      pinyin = line.split("\t")[1]
      definition = line.split("\t")[2]
      g1 = line.split("\t")[3]
      g2 = line.split("\t")[4]
      components = line.split("\t")[5].chomp
      if Hanzi.exists?(:character => hanzi)
        @hanzi = Hanzi.find_by(character: hanzi)
        @hanzi.components = components
        @hanzi.save
        pd_exists = Pinyindefinition.where(pinyin: pinyin).where(definition: definition).where(hanzi_id: @hanzi.id).exists?
        @hanzi.pinyindefinitions.create(pinyin: pinyin, definition: definition, gbeginning: g1, gending: g2) if pd_exists == false
      else
        @hanzi = Hanzi.create(character: hanzi, components: components)
        pd_exists = Pinyindefinition.where(pinyin: pinyin).where(definition: definition).where(hanzi_id: @hanzi.id).exists?
        @hanzi.pinyindefinitions.create(pinyin: pinyin, definition: definition, gbeginning: g1, gending: g2) if pd_exists == false
      end
      puts @hanzi.character
    end
  end
end

