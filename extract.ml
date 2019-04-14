open Yojson.Basic.Util
open Tokenizer
open Counter
open Similarity

let topics = [
  "David Gries";
  "Alan Turing";
  "Algorithm";
  "Anita Borg";
  "Apple";
  "Artifical Intelligence";
  "Barbara Liskov";
  "Bill Gates";
  "Computer Graphics";
  "Computer Science";
  "Computer Vision";
  "Cornell University";
  "David Gries";
  "Deep Learning";
  "Deepmind";
  "Distributed Computing";
  "Elon Musk";
  "Embedded Systems";
  "Facebook";
  "Grace Hopper";
  "Human Computer Interaction";
  "Intel";
  "iPad";
  "iPhone";
  "Jeff Bezos";
  "Logic";
  "Machine Learning";
  "Mark Zuckerberg";
  "Mathematics";
  "Microsoft";
  "Natural Language Processing";
  "Pinterest";
  "Privacy";
  "Programming Languages";
  "Reinforcement Learning";
  "Scott Belsky";
  "Sheryl Sandberg";
  "Silicon Valley";
  "Slack Technologies";
  "Steve Jobs";
  "Tesla";
  "Tracy Chou";
  "Turing Award";
  "Twitter";
  "Uber";
  "Venture Capital";
  "Warby Parker";
  "Amazon Company";
  "youTube";
]

type counter = Counter.t

type topic_dict = {
  topic : string;
  counter : counter;
}

type topic = {
  topic : string;
  content : string list;
}

(* open up the json file *)
let j = Yojson.Basic.from_file "corpus/data.json"

(* create topic type that has the topic and its content *)
let get_content (key_word:string) 
    (json: Yojson.Basic.json) : topic= 
  {
    topic = key_word;
    content = json |> member key_word  
              |> member "content" |> to_list 
              |> List.map to_string;
  }

(* given a string list of all topics, 
    this one gives you list of topic type *)
let rec all_topics (topics : string list) 
    (json : Yojson.Basic.json) (acc : topic list) : topic list = 
  match topics with 
  |word::t -> all_topics t (json) (get_content word json :: acc)
  |[] -> acc

(* given a topic/key word, this one gives 
   you a list of tokenized word of the content 
   of the topic *)
let tokenized_word_list (key_word:string) 
    (json: Yojson.Basic.json) 
    (acc:string list): string list = 
  List.concat (List.map Tokenizer.word_tokenize 
                 (get_content key_word json).content)

(* gives a counter type of the topic *)
let count_word (key_word:string) 
    (json: Yojson.Basic.json) 
    (acc:string list): counter = 
  Counter.make_dict (tokenized_word_list key_word json acc)

(* returns topic_dict data type that has 
    the topic and the counter dictionary 
    via a representation of record *)
let full_topic_dict (key_word:string) 
    (json: Yojson.Basic.json) : topic_dict = 
  {
    topic = key_word;
    counter = (count_word key_word json []);
  }

(* returns a list of topic_dict 
    type from a list of topics *)
let rec all_full_topics (topics : string list) 
    (json : Yojson.Basic.json) 
    (acc : topic_dict list) : topic_dict list = 
  match topics with 
  |word::t -> all_full_topics t 
                json (full_topic_dict word json :: acc)
  |[] -> acc

(* this function actually creates a list of 
   topic_dict from the topic list we have above *)
let all_topic_dict_counter = all_full_topics topics j []

(* a getter function that allows us to use 
    List.map in the following *)
let get_counter topic_dict =
  topic_dict.counter

(* print helper function to visualize 
    `topic_dict list` from `all_topic_dict_counter` *)
let rec print_topic_dict_list = function 
  |  [] -> ()
  |  (e:topic_dict)::l -> print_string e.topic ; 
    print_string " | " ; print_topic_dict_list l

(* given a word, this function checks every 
    topic_dict generated from the above topic list, 
    and if the word is in the topic_dict's counter 
    dictionary, then we add that entire topic_dict 
    type to the accumulator  *)
let rec which_dict_has_the_word (word:string)
    (topic_dict_lst:topic_dict list)
    (acc:topic_dict list): topic_dict list =
  match topic_dict_lst with
  |topic_dict::lst-> 
    if Counter.mem (Tokenizer.make_lower word) topic_dict.counter 
    then which_dict_has_the_word (Tokenizer.make_lower word) 
        lst (topic_dict::acc) 
    else which_dict_has_the_word 
        (Tokenizer.make_lower word) lst acc
  |[]->acc

(* the above function only process one word; 
      this one just patterns matches a string 
      list and merge each `topic_dict list` into 
      a whole list with removing duplicates *)
let rec process_phrase (words:string list)
    (topic_dict_lst:topic_dict list)
    (acc:topic_dict list) : topic_dict list = 
  match words with
  |word::lst -> (process_phrase lst topic_dict_lst 
                   (which_dict_has_the_word word topic_dict_lst []))
  |[]->acc

(* a wrapper pretty much that uses tokenize a string into a 
   string list and apply the above function to generate a 
   `topic_dict list` and use `Similarity.remove_dups` to remove duplicates*)
let which_dict_has_the_words (words)(topic_dict_lst)(acc)= 
  let tokens = Tokenizer.word_tokenize words in
  Similarity.remove_dups (process_phrase tokens topic_dict_lst acc)

let rec most_common_dict (word:string)(topic_dict_lst:topic_dict list)
    (max:int)(acc:topic_dict) : topic_dict =
  match topic_dict_lst with
  |topic_dict::lst -> 
    print_string "run ";
    let counter = get_counter topic_dict in
    let occurance = Counter.find_word word counter in
    let topic_dict_2 =  most_common_dict word lst occurance topic_dict in
    let counter_2 = get_counter topic_dict_2 in
    let occurance_2 = Counter.find_word word counter_2 in
    if occurance_2 > occurance
    then most_common_dict word lst occurance_2 topic_dict_2
    else most_common_dict word lst max topic_dict
  |[] -> acc

let rec most_common (word:string)(topic_dict_lst:topic_dict list)(max:int) : topic_dict =
  let topics_that_have_the_word = which_dict_has_the_words word topic_dict_lst [] in
  let acc = List.hd topics_that_have_the_word in
  most_common_dict word topics_that_have_the_word 0 acc

(** [term_frequency t] computes the term frequency of a word [t], where term
    frequency is defined as follows:
    # of times [t] appears in a document / total number of terms in document *)
let term_frequency t d = failwith "Unimplemented"


