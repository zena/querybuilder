# line 1 "lib/pseudo_sql_parser.rl"
=begin
"letters where foo > 5 from managers in site limit 5 group by section_id"
==>
[:group,
  [:limit,
    [:from,
      [:filter,
        [:relation,
          "letters"
        ],
        [:>,
          "foo",
          "5"
        ]
      ]
      [:relation,
        [:scope,
          "managers",
          "site"
        ]
      ]
    ],
    "5"
  ],
  "section_id"
]
=end
class PseudoSQLParser
  # http://dev.mysql.com/doc/refman/5.1/en/operator-precedence.html
  OP_PRECEDENCE = {
    "INTERVAL" => 40,
    "BINARY"   => 39, "COLLATE"  => 39,
    "!" => 38,
    "@-" => 37, "@~" => 37,
    "^" => 36,
    "*" => 35, "/" => 35, "DIV" => 35, "%" => 35, "MOD" => 35,
    "-" => 34, "+" => 34,
    "<<" => 33, ">>" => 33,
    "&" => 32,
    "|" => 31,
    "=" => 30, "<=>" => 30, ">=" => 30, ">" => 30, "<=" => 30, "<" => 30, "<>" => 30, "!=" => 30, "IS" => 30, "LIKE" => 30, "REGEXP" => 30, "IN" => 30,
    "BETWEEN" => 29, "CASE" => 29, "WHEN" => 29, "THEN" => 29, "ELSE" => 29,
    "NOT" => 28,
    "&&" => 27, "AND" => 27,
    "XOR" => 26,
    "||" => 25, "OR" => 25,
    ":=" => 24,
    "RELATION" => 13, "FILTER" => 13,
    "SCOPE" => 12,
    "FROM" => 11,
    "ASC"  => 10, "DESC" => 10,
    "CLAUSE" => 5,
    "CLAUSE_AND" => 4,
    "CLAUSE_OR" => 3,
    "OFFSET" => 2, "PAGINATE" => 2, "LIMIT" => 2, "ORDER" => 2, "GROUP" => 2,
    "QUERY" => 1,
    "PAR_CLOSE" => 0,
    "PAR" => -1,
  }
  # group < from < filter < relation < scope

  # simple_state_machine.rl
  # line 226 "lib/pseudo_sql_parser.rl"


  
# line 69 "lib/pseudo_sql_parser.rb"
class << self
	attr_accessor :_pseudo_sql_actions
	private :_pseudo_sql_actions, :_pseudo_sql_actions=
end
self._pseudo_sql_actions = [
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9, 1, 10, 1, 
	11, 1, 12, 1, 13, 1, 14, 1, 
	15, 1, 16, 1, 17, 1, 18, 1, 
	19, 1, 20, 1, 21, 2, 1, 0, 
	2, 1, 11, 2, 2, 0, 2, 2, 
	11, 2, 3, 0, 2, 3, 11, 2, 
	4, 0, 2, 4, 11, 2, 7, 0, 
	2, 7, 10, 2, 8, 0, 2, 8, 
	11, 2, 13, 0, 2, 15, 0, 2, 
	16, 0, 2, 17, 0, 2, 18, 0, 
	2, 19, 0
]

class << self
	attr_accessor :_pseudo_sql_key_offsets
	private :_pseudo_sql_key_offsets, :_pseudo_sql_key_offsets=
end
self._pseudo_sql_key_offsets = [
	0, 0, 8, 16, 26, 27, 28, 29, 
	37, 38, 39, 40, 41, 44, 48, 49, 
	57, 65, 74, 78, 79, 82, 90, 98, 
	106, 109, 110, 111, 114, 115, 116, 117, 
	123, 129, 131, 137, 144, 150, 152, 157, 
	163, 165, 166, 167, 168, 169, 175, 181, 
	183, 188, 194, 195, 196, 197, 198, 201, 
	205, 206, 214, 222, 231, 240, 241, 242, 
	246, 251, 252, 253, 254, 255, 256, 257, 
	258, 259, 260, 261, 262, 270, 278, 286, 
	291, 292, 293, 294, 295, 296, 299, 313, 
	315, 323, 345, 359, 361, 361, 365, 373, 
	389, 404, 406, 417, 418, 419, 422, 436, 
	449, 450, 451, 460, 463, 465, 466, 467, 
	468, 471, 475, 476, 477, 479, 483, 491, 
	492, 493, 494, 496, 497, 498, 499, 500, 
	501, 502, 503, 504, 505, 506, 507, 508, 
	509, 510, 511, 512, 513, 515, 525, 525, 
	539, 541, 550, 569, 583, 585, 585, 589, 
	598, 611, 626, 628, 640, 642, 653, 667, 
	668, 669, 672, 686, 687, 688, 689, 690, 
	691, 694, 698, 699, 700, 701, 711, 720, 
	721, 722, 723, 725, 726, 727, 728, 729, 
	730, 731, 732, 733, 734, 735, 736, 737, 
	738, 739, 740, 741, 742, 742, 746, 751, 
	760, 765, 771, 777, 784, 792, 814, 830, 
	840
]

class << self
	attr_accessor :_pseudo_sql_trans_keys
	private :_pseudo_sql_trans_keys, :_pseudo_sql_trans_keys=
end
self._pseudo_sql_trans_keys = [
	32, 95, 9, 10, 65, 90, 97, 122, 
	9, 10, 32, 95, 65, 90, 97, 122, 
	32, 102, 103, 105, 108, 111, 112, 119, 
	9, 10, 114, 111, 109, 32, 95, 9, 
	10, 65, 90, 97, 122, 114, 111, 117, 
	112, 32, 9, 10, 32, 98, 9, 10, 
	121, 32, 95, 9, 10, 65, 90, 97, 
	122, 32, 95, 9, 10, 65, 90, 97, 
	122, 9, 10, 32, 44, 95, 65, 90, 
	97, 122, 32, 44, 9, 10, 110, 32, 
	9, 10, 32, 95, 9, 10, 65, 90, 
	97, 122, 9, 10, 32, 95, 65, 90, 
	97, 122, 32, 102, 103, 108, 111, 112, 
	9, 10, 97, 105, 111, 110, 100, 32, 
	9, 10, 109, 105, 116, 32, 45, 9, 
	10, 48, 57, 32, 45, 9, 10, 48, 
	57, 48, 57, 9, 10, 32, 44, 48, 
	57, 32, 44, 103, 111, 112, 9, 10, 
	32, 45, 9, 10, 48, 57, 48, 57, 
	9, 10, 32, 48, 57, 32, 103, 111, 
	112, 9, 10, 102, 114, 102, 115, 101, 
	116, 32, 45, 9, 10, 48, 57, 32, 
	45, 9, 10, 48, 57, 48, 57, 9, 
	10, 32, 48, 57, 32, 103, 111, 112, 
	9, 10, 114, 100, 101, 114, 32, 9, 
	10, 32, 98, 9, 10, 121, 32, 95, 
	9, 10, 65, 90, 97, 122, 32, 95, 
	9, 10, 65, 90, 97, 122, 9, 10, 
	32, 44, 95, 65, 90, 97, 122, 32, 
	44, 65, 68, 97, 100, 103, 9, 10, 
	83, 67, 9, 10, 32, 44, 32, 44, 
	103, 9, 10, 69, 115, 99, 101, 97, 
	103, 105, 110, 97, 116, 101, 32, 95, 
	9, 10, 65, 90, 97, 122, 32, 95, 
	9, 10, 65, 90, 97, 122, 9, 10, 
	32, 95, 65, 90, 97, 122, 32, 103, 
	111, 9, 10, 114, 104, 101, 114, 101, 
	32, 9, 10, 32, 34, 39, 40, 45, 
	95, 9, 10, 48, 57, 65, 90, 97, 
	122, 34, 92, 9, 10, 32, 43, 45, 
	61, 60, 62, 32, 43, 45, 61, 97, 
	100, 102, 103, 104, 105, 108, 109, 110, 
	111, 112, 115, 119, 121, 9, 10, 60, 
	62, 32, 34, 39, 40, 45, 95, 9, 
	10, 48, 57, 65, 90, 97, 122, 39, 
	92, 32, 41, 9, 10, 9, 10, 32, 
	43, 45, 61, 60, 62, 32, 43, 45, 
	61, 97, 102, 103, 105, 108, 110, 111, 
	112, 9, 10, 60, 62, 32, 34, 39, 
	40, 45, 61, 95, 9, 10, 48, 57, 
	65, 90, 97, 122, 48, 57, 9, 10, 
	32, 43, 45, 46, 61, 48, 57, 60, 
	62, 110, 100, 32, 9, 10, 32, 34, 
	39, 40, 45, 95, 9, 10, 48, 57, 
	65, 90, 97, 122, 9, 10, 32, 43, 
	45, 61, 95, 60, 62, 65, 90, 97, 
	122, 97, 121, 9, 10, 32, 43, 45, 
	61, 115, 60, 62, 97, 105, 111, 107, 
	109, 101, 111, 116, 32, 9, 10, 32, 
	108, 9, 10, 105, 107, 102, 114, 32, 
	100, 9, 10, 9, 10, 32, 43, 45, 
	61, 60, 62, 111, 117, 114, 105, 111, 
	110, 117, 116, 101, 110, 116, 104, 101, 
	99, 111, 110, 100, 101, 101, 107, 101, 
	97, 48, 57, 9, 10, 32, 43, 45, 
	61, 48, 57, 60, 62, 32, 34, 39, 
	40, 45, 95, 9, 10, 48, 57, 65, 
	90, 97, 122, 34, 92, 32, 41, 43, 
	45, 61, 9, 10, 60, 62, 32, 41, 
	43, 45, 61, 97, 100, 104, 108, 109, 
	110, 111, 115, 119, 121, 9, 10, 60, 
	62, 32, 34, 39, 40, 45, 95, 9, 
	10, 48, 57, 65, 90, 97, 122, 39, 
	92, 32, 41, 9, 10, 32, 41, 43, 
	45, 61, 9, 10, 60, 62, 32, 41, 
	43, 45, 61, 97, 108, 110, 111, 9, 
	10, 60, 62, 32, 34, 39, 40, 45, 
	61, 95, 9, 10, 48, 57, 65, 90, 
	97, 122, 48, 57, 32, 41, 43, 45, 
	46, 61, 9, 10, 48, 57, 60, 62, 
	48, 57, 32, 41, 43, 45, 61, 9, 
	10, 48, 57, 60, 62, 32, 41, 43, 
	45, 61, 95, 9, 10, 60, 62, 65, 
	90, 97, 122, 110, 100, 32, 9, 10, 
	32, 34, 39, 40, 45, 95, 9, 10, 
	48, 57, 65, 90, 97, 122, 105, 107, 
	101, 111, 116, 32, 9, 10, 32, 108, 
	9, 10, 114, 97, 121, 32, 41, 43, 
	45, 61, 115, 9, 10, 60, 62, 32, 
	41, 43, 45, 61, 9, 10, 60, 62, 
	111, 117, 114, 105, 111, 110, 117, 116, 
	101, 110, 116, 104, 101, 99, 111, 110, 
	100, 101, 101, 107, 101, 97, 32, 44, 
	9, 10, 32, 44, 103, 9, 10, 32, 
	44, 65, 68, 97, 100, 103, 9, 10, 
	32, 103, 111, 9, 10, 32, 103, 111, 
	112, 9, 10, 32, 103, 111, 112, 9, 
	10, 32, 44, 103, 111, 112, 9, 10, 
	32, 102, 103, 108, 111, 112, 9, 10, 
	32, 43, 45, 61, 97, 100, 102, 103, 
	104, 105, 108, 109, 110, 111, 112, 115, 
	119, 121, 9, 10, 60, 62, 32, 43, 
	45, 61, 97, 102, 103, 105, 108, 110, 
	111, 112, 9, 10, 60, 62, 32, 102, 
	103, 105, 108, 111, 112, 119, 9, 10, 
	0
]

class << self
	attr_accessor :_pseudo_sql_single_lengths
	private :_pseudo_sql_single_lengths, :_pseudo_sql_single_lengths=
end
self._pseudo_sql_single_lengths = [
	0, 2, 4, 8, 1, 1, 1, 2, 
	1, 1, 1, 1, 1, 2, 1, 2, 
	2, 5, 2, 1, 1, 2, 4, 6, 
	3, 1, 1, 1, 1, 1, 1, 2, 
	2, 0, 4, 5, 2, 0, 3, 4, 
	2, 1, 1, 1, 1, 2, 2, 0, 
	3, 4, 1, 1, 1, 1, 1, 2, 
	1, 2, 2, 5, 7, 1, 1, 4, 
	3, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 2, 2, 4, 3, 
	1, 1, 1, 1, 1, 1, 6, 2, 
	6, 18, 6, 2, 0, 2, 6, 12, 
	7, 0, 7, 1, 1, 1, 6, 7, 
	1, 1, 7, 3, 2, 1, 1, 1, 
	1, 2, 1, 1, 2, 2, 6, 1, 
	1, 1, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 0, 6, 0, 6, 
	2, 5, 15, 6, 2, 0, 2, 5, 
	9, 7, 0, 6, 0, 5, 6, 1, 
	1, 1, 6, 1, 1, 1, 1, 1, 
	1, 2, 1, 1, 1, 6, 5, 1, 
	1, 1, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 0, 2, 3, 7, 
	3, 4, 4, 5, 6, 18, 12, 8, 
	0
]

class << self
	attr_accessor :_pseudo_sql_range_lengths
	private :_pseudo_sql_range_lengths, :_pseudo_sql_range_lengths=
end
self._pseudo_sql_range_lengths = [
	0, 3, 2, 1, 0, 0, 0, 3, 
	0, 0, 0, 0, 1, 1, 0, 3, 
	3, 2, 1, 0, 1, 3, 2, 1, 
	0, 0, 0, 1, 0, 0, 0, 2, 
	2, 1, 1, 1, 2, 1, 1, 1, 
	0, 0, 0, 0, 0, 2, 2, 1, 
	1, 1, 0, 0, 0, 0, 1, 1, 
	0, 3, 3, 2, 1, 0, 0, 0, 
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 3, 3, 2, 1, 
	0, 0, 0, 0, 0, 1, 4, 0, 
	1, 2, 4, 0, 0, 1, 1, 2, 
	4, 1, 2, 0, 0, 1, 4, 3, 
	0, 0, 1, 0, 0, 0, 0, 0, 
	1, 1, 0, 0, 0, 1, 1, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1, 2, 0, 4, 
	0, 2, 2, 4, 0, 0, 1, 2, 
	2, 4, 1, 3, 1, 3, 4, 0, 
	0, 1, 4, 0, 0, 0, 0, 0, 
	1, 1, 0, 0, 0, 2, 2, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	1, 1, 1, 1, 1, 2, 2, 1, 
	0
]

class << self
	attr_accessor :_pseudo_sql_index_offsets
	private :_pseudo_sql_index_offsets, :_pseudo_sql_index_offsets=
end
self._pseudo_sql_index_offsets = [
	0, 0, 6, 13, 23, 25, 27, 29, 
	35, 37, 39, 41, 43, 46, 50, 52, 
	58, 64, 72, 76, 78, 81, 87, 94, 
	102, 106, 108, 110, 113, 115, 117, 119, 
	124, 129, 131, 137, 144, 149, 151, 156, 
	162, 165, 167, 169, 171, 173, 178, 183, 
	185, 190, 196, 198, 200, 202, 204, 207, 
	211, 213, 219, 225, 233, 242, 244, 246, 
	251, 256, 258, 260, 262, 264, 266, 268, 
	270, 272, 274, 276, 278, 284, 290, 297, 
	302, 304, 306, 308, 310, 312, 315, 326, 
	329, 337, 358, 369, 372, 373, 377, 385, 
	400, 412, 414, 424, 426, 428, 431, 442, 
	453, 455, 457, 466, 470, 473, 475, 477, 
	479, 482, 486, 488, 490, 493, 497, 505, 
	507, 509, 511, 514, 516, 518, 520, 522, 
	524, 526, 528, 530, 532, 534, 536, 538, 
	540, 542, 544, 546, 548, 550, 559, 560, 
	571, 574, 582, 600, 611, 614, 615, 619, 
	627, 639, 651, 653, 663, 665, 674, 685, 
	687, 689, 692, 703, 705, 707, 709, 711, 
	713, 716, 720, 722, 724, 726, 735, 743, 
	745, 747, 749, 752, 754, 756, 758, 760, 
	762, 764, 766, 768, 770, 772, 774, 776, 
	778, 780, 782, 784, 786, 787, 791, 796, 
	805, 810, 816, 822, 829, 837, 858, 873, 
	883
]

class << self
	attr_accessor :_pseudo_sql_trans_targs
	private :_pseudo_sql_trans_targs, :_pseudo_sql_trans_targs=
end
self._pseudo_sql_trans_targs = [
	1, 2, 1, 2, 2, 0, 3, 207, 
	3, 2, 2, 2, 0, 3, 4, 8, 
	19, 24, 40, 69, 81, 3, 0, 5, 
	0, 6, 0, 7, 0, 1, 2, 1, 
	2, 2, 0, 9, 0, 10, 0, 11, 
	0, 12, 0, 13, 13, 0, 13, 14, 
	13, 0, 15, 0, 16, 17, 16, 17, 
	17, 0, 16, 17, 16, 17, 17, 0, 
	18, 197, 18, 16, 17, 17, 17, 0, 
	18, 16, 18, 0, 20, 0, 21, 21, 
	0, 21, 22, 21, 22, 22, 0, 23, 
	204, 23, 22, 22, 22, 0, 23, 4, 
	8, 24, 40, 69, 23, 0, 25, 28, 
	80, 0, 26, 0, 27, 0, 1, 1, 
	0, 29, 0, 30, 0, 31, 0, 32, 
	33, 32, 34, 0, 32, 33, 32, 34, 
	0, 34, 0, 35, 203, 35, 36, 34, 
	0, 35, 36, 8, 40, 69, 35, 0, 
	36, 37, 36, 38, 0, 38, 0, 39, 
	202, 39, 38, 0, 39, 8, 40, 69, 
	39, 0, 41, 51, 0, 42, 0, 43, 
	0, 44, 0, 45, 0, 46, 47, 46, 
	48, 0, 46, 47, 46, 48, 0, 48, 
	0, 49, 201, 49, 48, 0, 49, 8, 
	50, 69, 49, 0, 51, 0, 52, 0, 
	53, 0, 54, 0, 55, 55, 0, 55, 
	56, 55, 0, 57, 0, 58, 59, 58, 
	59, 59, 0, 58, 59, 58, 59, 59, 
	0, 60, 199, 60, 58, 59, 59, 59, 
	0, 60, 58, 61, 65, 66, 68, 8, 
	60, 0, 62, 0, 63, 0, 64, 198, 
	64, 58, 0, 64, 58, 8, 64, 0, 
	61, 0, 67, 0, 63, 0, 66, 0, 
	70, 0, 71, 0, 72, 0, 73, 0, 
	74, 0, 75, 0, 76, 0, 77, 78, 
	77, 78, 78, 0, 77, 78, 77, 78, 
	78, 0, 79, 200, 79, 78, 78, 78, 
	0, 79, 8, 50, 79, 0, 27, 0, 
	82, 0, 83, 0, 84, 0, 85, 0, 
	86, 86, 0, 86, 87, 91, 93, 97, 
	103, 86, 98, 103, 103, 0, 88, 142, 
	87, 89, 205, 89, 90, 90, 90, 96, 
	0, 89, 90, 90, 90, 99, 104, 4, 
	8, 119, 19, 107, 122, 110, 116, 69, 
	130, 135, 138, 89, 96, 0, 86, 87, 
	91, 93, 97, 103, 86, 98, 103, 103, 
	0, 88, 92, 91, 91, 93, 94, 93, 
	0, 95, 206, 95, 90, 90, 90, 96, 
	0, 95, 90, 90, 90, 99, 4, 8, 
	19, 107, 110, 116, 69, 95, 96, 0, 
	86, 87, 91, 93, 97, 90, 103, 86, 
	98, 103, 103, 0, 98, 0, 89, 205, 
	89, 90, 90, 140, 90, 98, 96, 0, 
	100, 0, 101, 0, 102, 102, 0, 102, 
	87, 91, 93, 97, 103, 102, 98, 103, 
	103, 0, 89, 205, 89, 90, 90, 90, 
	103, 96, 103, 103, 0, 105, 0, 106, 
	0, 95, 206, 95, 90, 90, 90, 118, 
	96, 0, 25, 108, 80, 0, 109, 29, 
	0, 101, 0, 111, 0, 112, 0, 113, 
	113, 0, 113, 114, 113, 0, 115, 0, 
	109, 0, 41, 117, 0, 102, 52, 102, 
	0, 95, 206, 95, 90, 90, 90, 96, 
	0, 120, 0, 121, 0, 106, 0, 123, 
	127, 0, 124, 0, 125, 0, 126, 0, 
	106, 0, 128, 0, 129, 0, 106, 0, 
	131, 0, 132, 0, 133, 0, 134, 0, 
	106, 0, 136, 0, 137, 0, 106, 0, 
	139, 0, 121, 0, 141, 0, 89, 205, 
	89, 90, 90, 90, 141, 96, 0, 87, 
	143, 144, 148, 150, 154, 158, 143, 155, 
	158, 158, 0, 145, 196, 144, 146, 208, 
	147, 147, 147, 146, 153, 0, 146, 208, 
	147, 147, 147, 159, 171, 175, 163, 178, 
	166, 170, 186, 191, 194, 146, 153, 0, 
	143, 144, 148, 150, 154, 158, 143, 155, 
	158, 158, 0, 145, 149, 148, 148, 150, 
	151, 150, 0, 152, 208, 147, 147, 147, 
	152, 153, 0, 152, 208, 147, 147, 147, 
	159, 163, 166, 170, 152, 153, 0, 143, 
	144, 148, 150, 154, 147, 158, 143, 155, 
	158, 158, 0, 155, 0, 146, 208, 147, 
	147, 156, 147, 146, 155, 153, 0, 157, 
	0, 146, 208, 147, 147, 147, 146, 157, 
	153, 0, 146, 208, 147, 147, 147, 158, 
	146, 153, 158, 158, 0, 160, 0, 161, 
	0, 162, 162, 0, 162, 144, 148, 150, 
	154, 158, 162, 155, 158, 158, 0, 164, 
	0, 165, 0, 161, 0, 167, 0, 168, 
	0, 169, 169, 0, 169, 163, 169, 0, 
	161, 0, 172, 0, 173, 0, 152, 208, 
	147, 147, 147, 174, 152, 153, 0, 152, 
	208, 147, 147, 147, 152, 153, 0, 176, 
	0, 177, 0, 173, 0, 179, 183, 0, 
	180, 0, 181, 0, 182, 0, 173, 0, 
	184, 0, 185, 0, 173, 0, 187, 0, 
	188, 0, 189, 0, 190, 0, 173, 0, 
	192, 0, 193, 0, 173, 0, 195, 0, 
	177, 0, 144, 18, 16, 18, 0, 64, 
	58, 8, 64, 0, 60, 58, 61, 65, 
	66, 68, 8, 60, 0, 79, 8, 50, 
	79, 0, 49, 8, 50, 69, 49, 0, 
	39, 8, 40, 69, 39, 0, 35, 36, 
	8, 40, 69, 35, 0, 23, 4, 8, 
	24, 40, 69, 23, 0, 89, 90, 90, 
	90, 99, 104, 4, 8, 119, 19, 107, 
	122, 110, 116, 69, 130, 135, 138, 89, 
	96, 0, 95, 90, 90, 90, 99, 4, 
	8, 19, 107, 110, 116, 69, 95, 96, 
	0, 3, 4, 8, 19, 24, 40, 69, 
	81, 3, 0, 0, 0
]

class << self
	attr_accessor :_pseudo_sql_trans_actions
	private :_pseudo_sql_trans_actions, :_pseudo_sql_trans_actions=
end
self._pseudo_sql_trans_actions = [
	0, 1, 0, 1, 1, 0, 13, 13, 
	13, 1, 1, 1, 43, 0, 0, 0, 
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 39, 96, 39, 
	96, 96, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 37, 93, 37, 93, 
	93, 0, 0, 1, 0, 1, 1, 0, 
	9, 9, 9, 9, 1, 1, 1, 43, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 1, 1, 0, 25, 
	25, 25, 1, 1, 1, 43, 0, 0, 
	0, 1, 0, 0, 0, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 41, 41, 
	0, 0, 0, 0, 0, 0, 0, 33, 
	87, 33, 87, 0, 0, 1, 0, 1, 
	0, 1, 0, 5, 5, 5, 5, 1, 
	43, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 0, 1, 0, 1, 0, 5, 
	5, 5, 1, 43, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 27, 81, 27, 
	81, 0, 0, 1, 0, 1, 0, 1, 
	0, 5, 5, 5, 1, 43, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 35, 90, 35, 
	90, 90, 0, 0, 1, 0, 1, 1, 
	0, 9, 9, 9, 9, 1, 1, 1, 
	43, 0, 0, 1, 1, 1, 1, 0, 
	0, 0, 1, 0, 1, 0, 11, 11, 
	11, 11, 43, 0, 0, 0, 0, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 31, 84, 
	31, 84, 84, 0, 0, 1, 0, 1, 
	1, 0, 29, 29, 29, 1, 1, 1, 
	43, 0, 0, 0, 0, 0, 1, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	19, 19, 0, 0, 0, 0, 21, 1, 
	1, 0, 1, 1, 1, 0, 0, 0, 
	1, 3, 3, 3, 45, 45, 45, 45, 
	43, 0, 1, 1, 1, 1, 1, 0, 
	0, 1, 0, 1, 1, 1, 1, 0, 
	1, 1, 1, 0, 1, 0, 15, 15, 
	15, 72, 69, 69, 15, 69, 69, 69, 
	0, 0, 0, 1, 1, 0, 0, 0, 
	0, 0, 0, 0, 1, 1, 1, 1, 
	43, 0, 1, 1, 1, 1, 0, 0, 
	0, 1, 1, 1, 0, 0, 1, 0, 
	15, 15, 15, 72, 69, 1, 69, 15, 
	69, 69, 69, 0, 1, 0, 5, 5, 
	5, 51, 51, 1, 51, 1, 51, 43, 
	1, 0, 1, 0, 0, 0, 0, 15, 
	15, 15, 72, 69, 69, 15, 69, 69, 
	69, 0, 9, 9, 9, 63, 63, 63, 
	1, 63, 1, 1, 43, 1, 0, 1, 
	0, 17, 17, 17, 75, 75, 75, 0, 
	75, 43, 1, 1, 1, 0, 1, 0, 
	0, 1, 0, 1, 0, 1, 0, 15, 
	15, 0, 0, 1, 0, 0, 1, 0, 
	1, 0, 0, 1, 0, 0, 0, 0, 
	0, 17, 17, 17, 75, 75, 75, 75, 
	43, 1, 0, 1, 0, 1, 0, 1, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 7, 7, 
	7, 57, 57, 57, 1, 57, 43, 1, 
	0, 0, 0, 21, 1, 1, 0, 1, 
	1, 1, 0, 0, 0, 1, 3, 48, 
	45, 45, 45, 3, 45, 0, 0, 23, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0, 1, 0, 
	15, 15, 15, 72, 69, 69, 15, 69, 
	69, 69, 0, 0, 0, 1, 1, 0, 
	0, 0, 0, 0, 23, 1, 1, 1, 
	0, 1, 0, 0, 23, 1, 1, 1, 
	1, 1, 1, 1, 0, 1, 0, 15, 
	15, 15, 72, 69, 1, 69, 15, 69, 
	69, 69, 0, 1, 0, 5, 54, 51, 
	51, 1, 51, 5, 1, 51, 0, 1, 
	0, 7, 60, 57, 57, 57, 7, 1, 
	57, 0, 9, 66, 63, 63, 63, 1, 
	9, 63, 1, 1, 0, 1, 0, 1, 
	0, 0, 0, 0, 15, 15, 15, 72, 
	69, 69, 15, 69, 69, 69, 0, 1, 
	0, 1, 0, 1, 0, 1, 0, 1, 
	0, 15, 15, 0, 0, 1, 0, 0, 
	1, 0, 1, 0, 1, 0, 17, 78, 
	75, 75, 75, 0, 17, 75, 0, 17, 
	78, 75, 75, 75, 17, 75, 0, 1, 
	0, 1, 0, 1, 0, 1, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 1, 0, 1, 0, 
	1, 0, 1, 0, 0, 0, 43, 0, 
	0, 0, 0, 43, 0, 0, 1, 1, 
	1, 1, 0, 0, 43, 0, 0, 0, 
	0, 43, 0, 0, 0, 0, 0, 43, 
	0, 0, 0, 0, 0, 43, 0, 0, 
	0, 0, 0, 0, 43, 0, 0, 0, 
	1, 0, 0, 0, 43, 0, 1, 1, 
	1, 1, 1, 0, 0, 1, 0, 1, 
	1, 1, 1, 0, 1, 1, 1, 0, 
	1, 43, 0, 1, 1, 1, 1, 0, 
	0, 0, 1, 1, 1, 0, 0, 1, 
	43, 0, 0, 0, 0, 1, 0, 0, 
	0, 0, 43, 0, 0
]

class << self
	attr_accessor :_pseudo_sql_eof_actions
	private :_pseudo_sql_eof_actions, :_pseudo_sql_eof_actions=
end
self._pseudo_sql_eof_actions = [
	0, 0, 43, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 43, 0, 0, 0, 0, 43, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 43, 0, 0, 0, 43, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	43, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 43, 0, 0, 0, 43, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 43, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	43, 0, 0, 0, 0, 0, 43, 0, 
	0, 0, 43, 0, 0, 0, 0, 43, 
	0, 0, 43, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 43, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 43, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0
]

class << self
	attr_accessor :pseudo_sql_start
end
self.pseudo_sql_start = 1;
class << self
	attr_accessor :pseudo_sql_first_final
end
self.pseudo_sql_first_final = 197;
class << self
	attr_accessor :pseudo_sql_error
end
self.pseudo_sql_error = 0;

class << self
	attr_accessor :pseudo_sql_en_par
end
self.pseudo_sql_en_par = 143;
class << self
	attr_accessor :pseudo_sql_en_main
end
self.pseudo_sql_en_main = 1;

# line 229 "lib/pseudo_sql_parser.rl"

  def self.parse(string)
    data = "#{string}\n"
    stack = [[:query]]
    last  = stack.last
    str_buf    = ""
    eof = 0;
    
# line 640 "lib/pseudo_sql_parser.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = pseudo_sql_start
end
# line 237 "lib/pseudo_sql_parser.rl"
    
# line 648 "lib/pseudo_sql_parser.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	_goto_level = 0
	_resume = 10
	_eof_trans = 15
	_again = 20
	_test_eof = 30
	_out = 40
	while true
	_trigger_goto = false
	if _goto_level <= 0
	if p == pe
		_goto_level = _test_eof
		next
	end
	if cs == 0
		_goto_level = _out
		next
	end
	end
	if _goto_level <= _resume
	_keys = _pseudo_sql_key_offsets[cs]
	_trans = _pseudo_sql_index_offsets[cs]
	_klen = _pseudo_sql_single_lengths[cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if data[p] < _pseudo_sql_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p] > _pseudo_sql_trans_keys[_mid]
	           _lower = _mid + 1
	        else
	           _trans += (_mid - _keys)
	           _break_match = true
	           break
	        end
	     end # loop
	     break if _break_match
	     _keys += _klen
	     _trans += _klen
	  end
	  _klen = _pseudo_sql_range_lengths[cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if data[p] < _pseudo_sql_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p] > _pseudo_sql_trans_keys[_mid+1]
	          _lower = _mid + 2
	        else
	          _trans += ((_mid - _keys) >> 1)
	          _break_match = true
	          break
	        end
	     end # loop
	     break if _break_match
	     _trans += _klen
	  end
	end while false
	cs = _pseudo_sql_trans_targs[_trans]
	if _pseudo_sql_trans_actions[_trans] != 0
		_acts = _pseudo_sql_trans_actions[_trans]
		_nacts = _pseudo_sql_actions[_acts]
		_acts += 1
		while _nacts > 0
			_nacts -= 1
			_acts += 1
			case _pseudo_sql_actions[_acts - 1]
when 0 then
# line 66 "lib/pseudo_sql_parser.rl"
		begin

      str_buf += data[p].chr
    		end
# line 66 "lib/pseudo_sql_parser.rl"
when 1 then
# line 70 "lib/pseudo_sql_parser.rl"
		begin

      last << [:string, str_buf]
      str_buf = ""
    		end
# line 70 "lib/pseudo_sql_parser.rl"
when 2 then
# line 75 "lib/pseudo_sql_parser.rl"
		begin

      puts str_buf.inspect
      last << [:integer, str_buf]
      str_buf = ""
    		end
# line 75 "lib/pseudo_sql_parser.rl"
when 3 then
# line 81 "lib/pseudo_sql_parser.rl"
		begin

      last << [:real, str_buf]
      str_buf = ""
    		end
# line 81 "lib/pseudo_sql_parser.rl"
when 4 then
# line 86 "lib/pseudo_sql_parser.rl"
		begin

      last << [:field, str_buf]
      str_buf = ""
    		end
# line 86 "lib/pseudo_sql_parser.rl"
when 5 then
# line 91 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, str_buf.downcase.to_sym, false)
      str_buf = ""
    		end
# line 91 "lib/pseudo_sql_parser.rl"
when 6 then
# line 96 "lib/pseudo_sql_parser.rl"
		begin

      last = insert(stack, [:relation, str_buf])
      str_buf = ""
    		end
# line 96 "lib/pseudo_sql_parser.rl"
when 7 then
# line 101 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, str_buf.to_sym)
      debug_stack(stack, str_buf.to_sym)
      str_buf = ""
    		end
# line 101 "lib/pseudo_sql_parser.rl"
when 8 then
# line 107 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :interval)
      last << str_buf
      str_buf = ""
    		end
# line 107 "lib/pseudo_sql_parser.rl"
when 9 then
# line 113 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :filter)
    		end
# line 113 "lib/pseudo_sql_parser.rl"
when 10 then
# line 117 "lib/pseudo_sql_parser.rl"
		begin

      # remember current machine state 'cs'
      last << [:par, cs]
      stack.push last.last
        debug_stack(stack, cs)
      last = last.last
      	begin
		cs = 143
		_trigger_goto = true
		_goto_level = _again
		break
	end

      debug_stack(stack, cs)
    		end
# line 117 "lib/pseudo_sql_parser.rl"
when 11 then
# line 127 "lib/pseudo_sql_parser.rl"
		begin

      debug_stack(stack, 'closing')
      pop_stack(stack, :par_close)
      # reset machine state 'cs'
      cs = stack.last.delete_at(1)
      # one more time to remove [:par...] line
      stack.pop 
      last = stack.last
      debug_stack(stack, 'done')
      # closing ')' must be parsed twice
      p = p - 1;
    		end
# line 127 "lib/pseudo_sql_parser.rl"
when 12 then
# line 140 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :scope)
      last << str_buf
      str_buf = ""
    		end
# line 140 "lib/pseudo_sql_parser.rl"
when 13 then
# line 146 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :offset)
    		end
# line 146 "lib/pseudo_sql_parser.rl"
when 14 then
# line 150 "lib/pseudo_sql_parser.rl"
		begin

      last << [:param, str_buf]
      str_buf = ""
    		end
# line 150 "lib/pseudo_sql_parser.rl"
when 15 then
# line 155 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :paginate)
    		end
# line 155 "lib/pseudo_sql_parser.rl"
when 16 then
# line 159 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :limit)
      str_buf = ""
    		end
# line 159 "lib/pseudo_sql_parser.rl"
when 17 then
# line 164 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :order)
      str_buf = ""
    		end
# line 164 "lib/pseudo_sql_parser.rl"
when 18 then
# line 169 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :group)
    		end
# line 169 "lib/pseudo_sql_parser.rl"
when 19 then
# line 173 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, :from)
    		end
# line 173 "lib/pseudo_sql_parser.rl"
when 20 then
# line 177 "lib/pseudo_sql_parser.rl"
		begin

      last = apply_op(stack, "clause_#{str_buf}".to_sym)
      str_buf = ""
    		end
# line 177 "lib/pseudo_sql_parser.rl"
when 21 then
# line 186 "lib/pseudo_sql_parser.rl"
		begin

      p = p - 1;
      raise Exception.new("Syntax error near '#{data[p..-1]}'.")
    		end
# line 186 "lib/pseudo_sql_parser.rl"
# line 921 "lib/pseudo_sql_parser.rb"
			end # action switch
		end
	end
	if _trigger_goto
		next
	end
	end
	if _goto_level <= _again
	if cs == 0
		_goto_level = _out
		next
	end
	p += 1
	if p != pe
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if p == eof
	__acts = _pseudo_sql_eof_actions[cs]
	__nacts =  _pseudo_sql_actions[__acts]
	__acts += 1
	while __nacts > 0
		__nacts -= 1
		__acts += 1
		case _pseudo_sql_actions[__acts - 1]
when 21 then
# line 186 "lib/pseudo_sql_parser.rl"
		begin

      p = p - 1;
      raise Exception.new("Syntax error near '#{data[p..-1]}'.")
    		end
# line 186 "lib/pseudo_sql_parser.rl"
# line 957 "lib/pseudo_sql_parser.rb"
		end # eof action switch
	end
	if _trigger_goto
		next
	end
end
	end
	if _goto_level <= _out
		break
	end
	end
	end
# line 238 "lib/pseudo_sql_parser.rl"
    puts data[p..-1].inspect
    stack.first
  end
  
  def self.apply_op(stack, op, change_last = true)
    pop_stack(stack, op)
    last = stack.last
    change_elem = last.last
    last[-1] = [op.to_sym, change_elem]
    if change_last
      stack.push last[-1]
    end
    stack.last
  end
  
  def self.insert(stack, arg)
    # insert [:relation, "..."]
    # stack: [[:query]]  --> [[:query, [:relation, "..."]], [:relation, "..."]]
    pop_stack(stack, arg.first)
    last = stack.last
    last << arg
    stack.push last.last
    stack.last
  end
  
  def self.pop_stack(stack, op)
    stack_op = stack.last.first
      puts [op, stack_op].inspect
    while OP_PRECEDENCE[op.to_s.upcase] <= OP_PRECEDENCE[stack_op.to_s.upcase]
      stack.pop
      stack_op = stack.last.first
        puts [op, stack_op].inspect
    end
  end
  
  def self.debug_stack(stack, msg = '')
    puts "======= #{msg} ======="
    stack.reverse_each do |s|
      puts s.inspect
    end
    puts "======================"
  end
end
