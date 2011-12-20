DEBUG=false

#class that holds the individual rule. 
class Rule
  attr_accessor :type, :class, :del, :add, :when, :rules

  def initialize(rule)    
    @type, @class, @del, @add, @when = rule.split.map {|x| x.strip}
    @add = @add.split("/")[0] if @add
  end

  def match? word
    return false unless word    
    word.strip.end_with? @add
  end

  def root word
    return nil unless match? word
    repl = (@del == "0") ? "" : @del
    word.sub(/#{@add}/, repl)
  end

  def to_s
    "#{@type} #{@class} #{@del} #{@add} #{@when}"
  end
end


#class that manages all the rules. 
class RuleMachine
    @rules = []
    @dict = []
    @doubt_file = nil
    @doubt_suffixes = ''
        

  def initialize rule_file,dictionary
    rules_loader rule_file
    @dict = File.open(dictionary).readlines.map {|z| z.strip}
    @dict = @dict.delete_if {|x| x =~ /^\d+$/}
    @doubt_file = File.new('doubt_file.txt','w+')
    @doubt_suffixes = File.open('doubt_suffixes.txt','r').readlines[0].split(',').join('|') if File.exist? 'doubt_suffixes.txt' 
    puts "doubt_suffixes = #{@doubt_suffixes}"

    puts "loaded #{@dict.size} words into @dict from file #{dictionary}"
  end

  def rules_loader rule_file
      @rules = []
      File.open(rule_file).readlines.each do |line|
        next if line.strip.empty?
        next unless line =~ /^SFX/ #load only SFX rules
        rule = Rule.new(line) unless line =~ /^[A-Z]+ [A-Za-z] [Y|N] [0-9]+$/
        @rules<<rule if rule
      end
  end 
  
  def valid? word
    puts "validating #{word}" if DEBUG
    @dict.include? word
  end

  #get the word and return its root word and rules.
  def parse word    
    root = ""
    rules = []
    word = word.strip
    rules.concat word.split("/")[1].split(//) if word.include? "/"

    word_sans_rules = word.split("/")[0]

    @rules.each do |rule|
      if (root_word = rule.root (word_sans_rules)) 
        puts "root_word = #{root_word}" if DEBUG
        if valid? root_word
          puts "root of #{word} => #{root_word}" if DEBUG

          # if the root word is got by just removing one letter, like ம் then there is a change that this word could as well be a root word. 
          # (e.g) வணக்கம், by a rule breaks to வணக்க which is in the dict. so வணக்கம் is removed from the dic file. 
          # using this check, we can put this file into the doubt file, for manual check.  
          @doubt_file.puts word if word =~ /#{root_word}[#{@doubt_suffixes}]/ 
          root = root_word
          rules << rule.class
        end 
      end
    end
    puts "Is root empty? #{root.strip.empty?}" if DEBUG 
    puts "word_sans_rules : #{word_sans_rules}"  if DEBUG
    root = word_sans_rules if root.strip.empty?
    puts "root : #{root}" if DEBUG
    #(root.strip.size > 0) ? [root, rules] : []
    print "."
    [root, rules.uniq]
  end 
end


#process the word list. 
class WordParser

  @words = []


  def initialize(rule_file, dictionary)
    @rm = RuleMachine.new rule_file, dictionary
    puts "loaded rules from file #{rule_file}"
  end


  def match_word w
     result = @rm.parse w     
     p result
  end

  def match word_file, out_file
    puts "debug : #{DEBUG}"
    words = File.open(word_file).readlines.map {|z| z.strip}
    words = words.delete_if {|x| x =~ /^\d+$/} #delete if the line only has numbers. 
    puts "loaded #{words.size} words into @words from file #{word_file}"

    root_words = Hash.new ([])

    words.each do |w|      
      next if w.empty?
      next if w =~ /^[0-9]$/
      result = @rm.parse w
      root_words[result[0]] = result[1] 
    end

    File.open(out_file,'w+') do |out|
      out.puts root_words.size
      root_words.each_entry do |w,r|
        out.puts w + "#{'/' + r.uniq.join if r.size > 0}"
      end
    end    
    puts "took #{word_file} and gave #{out_file}" 
    puts "word count in original file : #{words.size}"
    puts "word count in processed file : #{root_words.size}"
  end

end

t1 = Time.now
w = WordParser.new "ta_TA.aff","ta_complete.dic" 
#w.match "ta_complete.dic","ta_complete.dic"
w.match "ta_TA.dic.old","ta_TA.dic.new"
#w.match "test.txt","test.dic"
#word = File.open('test.txt','r').readlines[0]
#File.open('result.txt','w+') {|out| out.puts w.match_word word}
=begin
suffixes = ["","_2","_3","_4"]
suffixes.each do |suffix|
    file="ta_TA#{suffix}.dic.old"
    w = WordParser.new "ta_TA.aff",file,file
    print "start process on #{file}...."
    w.match
end
=end
t2 = Time.now

puts "done.\ntime taken : #{t2-t1} seconds"

