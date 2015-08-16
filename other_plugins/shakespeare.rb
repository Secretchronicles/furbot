# -*- coding: utf-8 -*-
#
# = Shakespeare plugin
#
# Dr. M.’s favourite literature in IRC!
#
# == Configuration
# None.
#
# == Author
# Marvin Gülker (Quintus)
#
# == License
# furbot’s.

class Cinch::Shakespeare
  include Cinch::Plugin

  # Quotes. One quote per line.
  QUOTES =<<SHAKESPEARE.split("\n").map(&:strip)
To be, or not to be: that is the question. (Hamlet, Act III, Scene I)
Shall I compare thee to a summer’s day? / Thou art more lovely and more temperate: / Rough winds do shake the darling buds of May, / And summer's lease hath all too short a date. (Sonnet 18)
Neither a borrower nor a lender be; For loan oft loses both itself and friend, and borrowing dulls the edge of husbandry. (Hamlet, Act I, Scene III)
This above all: to thine own self be true. (Hamlet, Act I, Scene III)
Though this be madness, yet there is method in ’t. (Hamlet, Act II, Scene III)
That it should come to this! (Hamlet, Act I, Scene II)
There is nothing either good or bad, but thinking makes it so. (Hamlet, Act II, Scene II)
What a piece of work is man! how noble in reason! how infinite in faculty! in form and moving how express and admirable! in action how like an angel! in apprehension how like a god! the beauty of the world, the paragon of animals! (Hamlet, Act II, Scene II)
The lady doth protest too much, methinks. (Hamlet, Act III, Scene II)
In my mind's eye. (Hamlet, Act I, Scene II)
A little more than kin, and less than kind. (Hamlet, Act II, Scene II)
The play 's the thing wherein I'll catch the conscience of the king. (Hamlet, Act II, Scene II)
And it must follow, as the night the day, thou canst not then be false to any man. (Hamlet, Act I, Scene III)
This is the very ecstasy of love. (Hamlet, Act II, Scene I)
Brevity is the soul of wit. (Hamlet, Act II, Scene II)
Rich gifts wax poor when givers prove unkind. (Hamlet, Act III, Scene II).
When sorrows come, they come not single spies, but in battalions. (Hamlet, Act IV, Scene V)
All the world ’s a stage, and all the men and women merely players. They have their exits and their entrances; And one man in his time plays many parts. (As You Like It, Act II, Scene VII)
Can one desire too much of a good thing? (As You Like It, Act IV, Scene I)
I like this place and willingly could waste my time in it. (As You Like It, Act II, Scene IV)
How bitter a thing it is to look into happiness through another man's eyes! (As You Like It, Act V, Scene II)
Blow, blow, thou winter wind! Thou art not so unkind as man's ingratitude. (As You Like It, Act II, Scene VII)
True is it that we have seen better days. (As You Like It, Act II, Scene VII)
For ever and a day. (As You Like It, Act IV, Scene I)
The fool doth think he is wise, but the wise man knows himself to be a fool. (As You Like It, Act V, Scene I)
A horse! a horse! my kingdom for a horse! (King Richard III, Act I, Scene IV)
Conscience is but a word that cowards use, devised at first to keep the strong in awe. (King Richard III, Act V, Scene III)
So wise so young, they say, do never live long. (King Richard III, Act III, Scene I)
Off with his head! (King Richard III, Act III, Scene I)
An honest tale speeds best, being plainly told. (King Richard III, Act IV, Scene IV)
The world is grown so bad, that wrens make prey where eagles dare not perch. (King Richard III, Act I, Scene III)
O Romeo, Romeo! wherefore art thou Romeo? (Romeo and Juliet, Act II, Scene II)
Tempt not a desperate man. (Romeo and Juliet, Act V, Scene III)
For you and I are past our dancing days. (Romeo and Juliet, Act I, Scene V)
O! she doth teach the torches to burn bright. (Romeo and Juliet, Act I, Scene V)
Not stepping o'er the bounds of modesty. (Romeo and Juliet, Act IV, Scene II)
If you prick us, do we not bleed? if you tickle us, do we not laugh? if you poison us, do we not die? and if you wrong us, shall we not revenge? (The Merchant of Venice, Act III, Scene I)
The devil can cite Scripture for his purpose. (The Merchant of Venice, Act I, Scene III)
I like not fair terms and a villain's mind. (The Merchant of Venice, Act I, Scene III)
What 's done is done. (Macbeth, Act III, Scene II)
Fair is foul, and foul is fair. (Macbeth, Act I, Scene I)
How sharper than a serpent's tooth it is to have a thankless child! (King Lear, Act I, Scene IV)
I am a man more sinned against than sinning. (King Lear, Act III, Scene II)
Nothing will come of nothing. (King Lear, Act I, Scene I)
Have more than thou showest, speak less than thou knowest, lend less than thou owest. (King Lear, Act I, Scene IV)
The worst is not, So long as we can say, “This is the worst.”. (King Lear, Act IV, Scene I)
‘T’is neither here nor there. (Othello, Act IV, Scene III)
I will wear my heart upon my sleeve for daws to peck at. (Othello, Act I, Scene I)
To mourn a mischief that is past and gone is the next way to draw new mischief on. (Othello, Act I, Scene III)
The robbed that smiles steals something from the thief. (Othello, Act I, Scene III)
My salad days, when I was green in judgment. (Antony and Cleopatra, Act I, Scene IV)
The game is up. (Cymbeline, Act III, Scene III)
I have not slept one wink. (Cymbeline, Act III, Scene III)
Be not afraid of greatness: some are born great, some achieve greatness and some have greatness thrust upon them. (Twelfth Night, Act II, Scene V)
Love sought is good, but giv'n unsought is better. (Twelfth Night, Act III, Scene I)
Men of few words are the best men. (King Henry the Fifth, Act III, Scene II)
The course of true love never did run smooth. (A Midsummer Night’s Dream, Act I, Scene I)
Everyone can master a grief but he that has it. (Much Ado About Nothing, Act III, Scene II)
These words are razors to my wounded heart. (Titus Andronicus, Act I, Scene I)
What 's gone and what 's past help should be past grief. (The Winter’s Tale, Act III, Scene II)
You pay a great deal too dear for what's given freely. (The Winter’s Tale, Act I, Scene I)
Out of the jaws of death. (Taming of the Shrew, Act III, Scene IV)
Thus the whirligig of time brings in his revenges. (Taming of the Shrew, Act V, Scene I)
For the rain it raineth every day. (Taming of the Shrew, Act V, Scene I)
The common curse of mankind, — folly and ignorance. (Troilus and Cressida, Act II, Scene III)
Nature teaches beasts to know their friends. (Coriolanus, Act II, Scene I)
SHAKESPEARE

  #listen_to :join,    :method => :on_join
  #listen_to :leaving, :method => :on_leaving
  listen_to :nick,    :method => :on_nick
  listen_to :channel, :method => :on_channel

  private

  [:on_join, :on_leaving, :on_nick].each do |sym|
    define_method(sym){ |msg| quote(msg.channel, 10) }
  end

  def on_channel(msg)
    quote(msg.channel, 2)
  end

  def quote(channel, likelihood)
    return if rand(1000) > likelihood

    ary = get_random_quote
    channel.send(ary[0])

    # Show source after some time. Time to guess :-)
    Timer(rand(120), :shots => 1) do
      channel.send("-- #{ary[1]}")
    end
  end

  def get_random_quote
    line = QUOTES.sample

    if line =~ /\((.*?)\)$/
      [$`, $1]
    else
      [line, "I do not know either."]
    end
  end

end
