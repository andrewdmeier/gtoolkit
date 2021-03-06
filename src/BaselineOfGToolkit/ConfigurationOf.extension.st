Extension { #name : #ConfigurationOf }

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtMapFor: aView [
	<gtView>
	^ self 
		gtMapFor: aView 
		selectRelationsThat: [ :aBaselineA :aBaselineB | true ]
		nameDisplayedAs: [ :aRopedText | aRopedText ]
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtMapFor: aView selectRelationsThat: aTwoArgBlock nameDisplayedAs: anOneArgBlock [
	^ aView mondrian
		title: 'Map';
		priority: 10;
		painting: [ :mondrian |
			| projects |
			projects := Set new.
			self project version 
				withDeep: [ :each | each projects collect: #version ]
				relationDo: [ :a :b | (aTwoArgBlock value: a value: b)
					ifTrue: [ projects add: a; add: b ] ].
			mondrian nodes 
				shape: [ :each | 
					| text element |
					text := [
						| displayString |
						displayString := (((each gtDisplayString 
							copyReplaceAll: 'BaselineOf' with: '')
							copyReplaceAll: 'ConfigurationOf' with: '')
							copyReplaceAll: 'GToolkit' with: 'GT ').
						(anOneArgBlock value: displayString) asRopedText glamorousRegularFont ]
						on: Error do: [ :e | e asString asRopedText foreground: BrGlamorousColors linkWithErrorColor ].
					element := BlTextElement new.
					element 	
						text: text; 
						zIndex: 1; 
						when: BlClickEvent do: [ :e | e consumed: true. element fireEvent: (GtPhlowObjectToSpawn new object: each spec project configuration class; sourceElement: element) ] ];
				with: projects.
			mondrian edges
				shape: [ :each |
					BlParabollaArcElement new 
						zIndex: 0;
						curvatureFraction: 0.2;
						border: (BlBorder paint: (Color gray alpha: 0.2) width: 2);
						toHead: (BlArrowheadSimpleArrow new
							border: (BlBorder builder paint: (Color gray alpha: 0.2); width: 2; build))  ];
				fromRightCenter;
				toLeftCenter;
				connectFrom: #yourself 
				toAll: [:each | |dependedProjects |
					dependedProjects := each projects collect: #version.
					projects select: [ :project | dependedProjects anySatisfy: [ :dependedProject | dependedProject = project ] ] ].
			mondrian layout custom: (GtGradHorizontalDominanceCenteredTreeLayout new levelDistance: 50; nodeDistance: 10)]
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtPackagesFor: aView [
	<gtView>
	^ aView explicit
		title: 'Packages';
		priority: 50;
		stencil: [ 
			| list |
			list := BrColumnedList new display: [ self project version packages ].
			list addEventHandler: GtInspectorListToSelectHandler new.
			list column
				title: 'Packages';
				stencil: [ :aNode :index |
					| text textElement |
					text := [ aNode gtDisplayString asRopedText ] 
						on: Error 
						do: [ aNode errorMessage asRopedText foreground: Color red ].
					textElement := (BrColumnCellLabelStencil matchParent: text) asElement.
					textElement constraintsDo: [ :c | c horizontal matchParent. c padding: (BlInsets left: 10) ] ].
			list ]
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtPackagesMapFor: aView [
	<gtView>
	^ aView mondrian
		title: 'Packages map';
		priority: 11;
		painting: [ :mondrian | self paintPackagesMapWith: mondrian]
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtPillarCommentFor: aView [
	^ (super gtPillarCommentFor: aView)
		priority: 0
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> gtProjectsFor: aView [
	<gtView>
	^ aView list
		title: 'Projects';
		priority: 10;
		items: [ self project version projects collect: [ :each | each version spec project configuration class ] ]
]

{ #category : #'*BaselineOfGToolkit' }
ConfigurationOf class >> paintPackagesMapWith: mondrian [
	| packages projects |
	packages := self project version packages.
	projects := self project version projects.
	mondrian nodes 
		stencil: [ :packageSpec |
			BlTextElement new text: packageSpec name asRopedText ];
		with: packages.
	mondrian nodes 
		stencil: [ :projectSpec |
			| element |
			element := BlTextElement new.
			element 
				when: BlClickEvent do: [ :e | e consumed: true. element fireEvent: (GtPhlowObjectToSpawn new object: (Smalltalk globals at: projectSpec constructClassName asSymbol); sourceElement: element) ];
				text: (projectSpec name asRopedText foreground: Color gray) ];
		with: projects.
	packages do: [ :p | 
		mondrian edges
			stencil: [ :x | 
				BlParabollaArcElement new 
					zIndex: 0;
					curvatureFraction: 0.2;
					border: (BlBorder paint: (Color gray alpha: 0.2) width: 2);
					toHead: (BlArrowheadSimpleArrow new
						border: (BlBorder builder paint: (Color gray alpha: 0.2); width: 2; build)) ]; 
			fromRightCenter;
			toLeftCenter;
			connect: (p requires collect: [ :symbol | 
				packages 
					detect: [:package | package name = symbol ]
					ifNone: [ projects detect: [ :project | project name = symbol ] ] ])
			from:	[ :x | p ]
			to: #yourself ].
	mondrian layout horizontalDominanceTree nodeDistance: 10; levelDistance: 20
]
