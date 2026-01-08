#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: diamond, circle

#set page(
  paper: "a4",
  margin: (x: 1.4cm),
)

#set document(title: [
  Assembly language exercises: \
  Project 17: Script-Based Music Playback
])
#show title: set text(size: 17pt)
#show title: set align(center)
#show title: set block(below: 1.2em)

#title()

#grid(
  columns: (1fr, 1fr),
  align(center)[
    Trần Quang Huy \
    202417135 \
    ICT 01 K69 \
  ],
  align(center)[
    Lê Đức Anh \
    202417135 \
    ICT 01 K69 \
  ]
)

= Project: Learn about system for music playback
- Write a program to play music
- Prepare 4 preset music tracks

From the requirements:
+ Present menu for user to choose track
+ Play the track chosen
+ Make it able to stop playback when user press "0"

Solutions:
+ User inputs are simple #sym.arrow Use Hexadecimal Keypad with interrupts to handle inputs
+ Inputs received for Keypad are in odd form (column-row in 2 nibbles) #sym.arrow use `lookup_table` to translate intention (load proper song address)
+ Use `s1` like a flag for "0" press to be able to stop the playback

#diagram(
  node-stroke: 1pt,
  node((0,0), [Start], corner-radius: 2pt),
  edge("-|>"),
  node((0,1), align(center)[
    Hey, wait,\ this flowchart\ is a trap!
  ], shape: circle),
  edge("d,r,u,l", "-|>", [Yes], label-pos: 0.1)
)
