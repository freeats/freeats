# frozen_string_literal: true

class Locations::Order
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :locations, Types::Strict::Array.of(Types::Instance(Location))
    option :query, Types::Strict::String
  end

  def call
    string_for_regex = Regexp.escape(query).chars.map { |letter| DIACRITICS[letter] || letter }.join
    regex = /#{string_for_regex}/i

    locations_with_score = locations.map do |location|
      location_score = calculate_score(name: location.name, query:, regex:)
      max_alias_score = location.aliases.map do |alias_name|
        calculate_score(name: alias_name, query:, regex:)
      end.max

      # All locations with population under `population_divider` are sorted by best-match.
      # All locations with population above `population_divider` are sorted by population.
      population_divider = 50_000.0
      score = [location_score, max_alias_score].max *
              [location.population / population_divider, 1].max

      { location:, score: }
    end

    Success(locations_with_score.sort_by { _1[:score] }.reverse.map { _1[:location] })
  end

  private

  def calculate_score(name:, query:, regex:)
    index = name.index(regex)
    return 0 if index.nil?

    score = query.size / name.size.to_f
    score += 0.5 if index.zero?
    score
  end

  DIACRITICS = {
    "a" => "[aḀḁĂăÂâǍǎȺⱥȦȧẠạÄäÀàÁáĀāÃãÅåąĄÃąĄ]",
    "b" => "[b␢βΒB฿𐌁ᛒ]",
    "c" => "[cĆćĈĉČčĊċC̄c̄ÇçḈḉȻȼƇƈɕᴄＣｃ]",
    "d" => "[dĎďḊḋḐḑḌḍḒḓḎḏĐđD̦d̦ƉɖƊɗƋƌᵭᶁᶑȡᴅＤｄð]",
    "e" => "[eÉéÈèÊêḘḙĚěĔĕẼẽḚḛẺẻĖėËëĒēȨȩĘęᶒɆɇȄȅẾếỀềỄễỂểḜḝḖḗḔḕȆȇẸẹỆệⱸᴇＥｅɘǝƏƐε]",
    "f" => "[fƑƒḞḟ]",
    "g" => "[gɢ₲ǤǥĜĝĞğĢģƓɠĠġ]",
    "h" => "[hĤĥĦħḨḩẖẖḤḥḢḣɦʰǶƕ]",
    "i" => "[iÍíÌìĬĭÎîǏǐÏïḮḯĨĩĮįĪīỈỉȈȉȊȋỊịḬḭƗɨɨ̆ᵻᶖİiIıɪＩｉ]",
    "j" => "[jȷĴĵɈɉʝɟʲ]",
    "k" => "[kƘƙꝀꝁḰḱǨǩḲḳḴḵκϰ₭]",
    "l" => "[lŁłĽľĻļĹĺḶḷḸḹḼḽḺḻĿŀȽƚⱠⱡⱢɫɬᶅɭȴʟＬｌ]",
    "n" => "[nŃńǸǹŇňÑñṄṅŅņṆṇṊṋṈṉN̈n̈ƝɲȠƞᵰᶇɳȵɴＮｎŊŋ]",
    "o" => "[oØøÖöÓóÒòÔôǑǒŐőŎŏȮȯỌọƟɵƠơỎỏŌōÕõǪǫȌȍՕօ]",
    "p" => "[pṔṕṖṗⱣᵽƤƥᵱ]",
    "q" => "[qꝖꝗʠɊɋꝘꝙq̃]",
    "r" => "[rŔŕɌɍŘřŖŗṘṙȐȑȒȓṚṛⱤɽ]",
    "s" => "[sŚśṠṡṢṣꞨꞩŜŝŠšŞşȘșS̈s̈]",
    "t" => "[tŤťṪṫŢţṬṭƮʈȚțṰṱṮṯƬƭ]",
    "u" => "[uŬŭɄʉỤụÜüÚúÙùÛûǓǔŰűŬŭƯưỦủŪūŨũŲųȔȕ∪]",
    "v" => "[vṼṽṾṿƲʋꝞꝟⱱʋ]",
    "w" => "[wẂẃẀẁŴŵẄẅẆẇẈẉ]",
    "x" => "[xẌẍẊẋχ]",
    "y" => "[yÝýỲỳŶŷŸÿỸỹẎẏỴỵɎɏƳƴ]",
    "z" => "[zŹźẐẑŽžŻżẒẓẔẕƵƶ]"
  }.freeze
end
