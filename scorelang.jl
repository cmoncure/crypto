export english

const english_frequency = (Char => Float32) [
    'E' => 12.02,
    'T' => 9.10,
    'A' => 8.12,
    'O' => 7.68,
    'I' => 7.31,
    'N' => 6.95,
    'S' => 6.28,
    'R' => 6.02,
    'H' => 5.92,
    'D' => 4.32,
    'L' => 3.98,
    'U' => 2.88,
    'C' => 2.71,
    'M' => 2.61,
    'F' => 2.30,
    'Y' => 2.11,
    'W' => 2.09,
    'G' => 2.03,
    'P' => 1.82,
    'B' => 1.49,
    'V' => 1.11,
    'K' => 0.69,
    'X' => 0.17,
    'Q' => 0.11,
    'J' => 0.10,
    'Z' => 0.07
    ]

const english_penalize_chars = "0123456789~@#\$\%^&*()_+-={}[]<>\/\:;"

const english_words = [
  "LIKE",
  "THE",
  "AND",
  "THAT",
  "HAVE",
  "WITH",
  "FROM",
  "YOUR",
  "NOT",
  "THEY",
  "SAY",
  "SHE",
  "WOULD",
  "THERE",
  "THEIR",
  "WHAT"
  ]

const languages = [
  "english" => (english_frequency, english_words, english_penalize_chars)
  ]

function character_frequency_score (test_str::ASCIIString, len::Uint, glyph_frequency_dict::Dict)
  frequency_variance::Float32 = float32(0.0)
  test_str = uppercase(test_str)
  for glyph = keys(glyph_frequency_dict)
    count = zero(Int32)
    idx = one(Int32)

    while idx < sizeof(test_str)
      if test_str[idx] == glyph
        count += 1
      end
      idx += 1
    end

    frequency = (count / len)
    difference = 100 * frequency - glyph_frequency_dict[glyph]
    frequency_variance += difference^2 / glyph_frequency_dict[glyph]

  end
  frequency_variance /= length(keys(glyph_frequency_dict))
  return 100 - frequency_variance
end

length(keys(english_frequency))

function common_substrings_score (test_str::ASCIIString, common_words::Vector{ASCIIString})
  score = int32(0)
  test_str = uppercase(test_str)
  for substring = common_words
      if contains(test_str, substring)
        score += length(substring) * 4
      end
  end
  return score
end

function penalty(x::Int, y::Int)
  e^(80 * (x / y)) / (e)
end

penalty(4, 50)

function penalize_garbage (test_str::ASCIIString, penalize_chars::String)
  non_text_glyphs::Int = 0
  for c in test_str
    if contains(penalize_chars, ascii([c]))
      non_text_glyphs += 1
    end
  end
#  println("penalty: ", e^(30 * (non_text_glyphs / length(test_str))) / (2e), " junk/total: ", non_text_glyphs, " / ", length(test_str))
  return penalty(non_text_glyphs, length(test_str))
end

function ascii_filter(s::Array{Uint8})
  if is_valid_ascii(s)
    return s
  end
  filter!(x -> is_valid_ascii([x]), s)
  @assert is_valid_ascii(s)
  s = ascii(s)
  @assert isa(s, ASCIIString)
  return s
end

function score_candidate_language(test_str::ASCIIString, len::Uint, language::String)
  score = character_frequency_score(test_str, len, languages[language][1])
  score += common_substrings_score(test_str, languages[language][2])
  score -= penalize_garbage(test_str, languages[language][3])
  return score
end

function score_candidate_language(test_str::Array{Uint8}, language::String)
  score_candidate_language(ascii(ascii_filter(test_str)), uint(length(test_str)), language)
end

function score_candidate_language_frequency_only(test_str::ASCIIString, len::Uint, language::String)
  score = character_frequency_score(test_str, len, languages[language][1])
  penalty = penalize_garbage(test_str, languages[language][3])
  overall = score - penalty
#   println("cleartext: ", test_str[1:40], " frequency score: ", score, " penalty: ", penalty, " overall: ", overall)
  if isnan(overall)
    overall = -99999999.9
  end
  return overall
end

function score_candidate_language_frequency_only(test_str::Array{Uint8}, language::String)
    score_candidate_language_frequency_only(ascii(ascii_filter(test_str)), uint(length(test_str)), language)
  end
