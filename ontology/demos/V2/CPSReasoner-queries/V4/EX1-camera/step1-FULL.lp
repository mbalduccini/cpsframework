% ------ Input Interface ------

property(P) :- input(P,"rdf:type","cpsf:Property").
descr(P,D) :- input(P,"rdfs:comment",D).
atomic_statement(P,A) :- input(P,"cpsf:atomicStatement",A).
isAssertion(P) :- input(P,"cpsf:hasType","cpsf:PropertyType_Assertion").
concern(S) :- input(S,"cpsf:includesConcern",O).
concern(O) :- input(S,"cpsf:includesConcern",O).
subconcern(S,O) :- input(S,"cpsf:includesConcern",O).
addressedBy(C,P) :- input(C,"cpsf:addressedByProperty",P).

-aspect(A) :-
	subconcern(_,A).

aspect(A) :-
	concern(A),
	not -aspect(A).

-isAssertion(P) :- property(P), not isAssertion(P).

% Identify the last step in the input
last_step(S) :-
	step(S),
	S2=S+1,
	not step(S2).


% ------ Theory ------

% A property is satisfied only if we have concrete evidence that
% all corresponding atomic statements hold.
% If we are uncertain about even just one, then the property is not satisfied.
-holds(sat_property(A),S) :-
	step(S),
	atomic_statement(P,A),
	isAssertion(P),
	not holds(A,S).

-holds(sat_concern(C),S) :-
	step(S),
	addressedBy(C,P),
	atomic_statement(P,A), 
	-holds(sat_property(A),S).

-holds(sat_concern(C1),S) :-
	step(S),
	subconcern(C1,C2),
	-holds(sat_concern(C2),S).

holds(sat_concern(C),S) :-
	step(S),
	concern(C),
	not -holds(sat_concern(C),S).

-holds(sat_all,S) :-
	step(S),
	aspect(A),
	-holds(sat_concern(A),S).

holds(sat_all,S) :-
	step(S),
	not -holds(sat_all,S).

% initial state of the CPS
fluent(A) :- atomic_statement(P,A).
fluent(A) :- config_feature(A).

holds(F,0) :-
	fluent(F),
	obs(F,true).

-holds(F,0) :-
	fluent(F),
	obs(F,false).

holds(F,0) :-
	fluent(F),
	assumed(F,true),
	not -holds(F,0).

-holds(F,0) :-
	fluent(F),
	assumed(F,false),
	not holds(F,0).

% next state: inertia axioms
is_defined(F) :- fluent(F), defined(M,F).

holds(F,S2) :-
	fluent(F),
	not is_defined(F),
	step(S), step(S2), S2=S+1,
	holds(F,S),
	not -holds(F,S2).

-holds(F,S2) :-
	fluent(F),
	not is_defined(F),
	step(S), step(S2), S2=S+1,
	-holds(F,S),
	not holds(F,S2).

holds(F,S) :-
	fluent(F),
	defined(neg,F),
	step(S),
	not -holds(F,S).

-holds(F,S) :-
	fluent(F),
	defined(pos,F),
	step(S),
	not holds(F,S).

% effect of a negative impact
-holds(A,S) :-
	impacted(neg,A,S).

% ------ Output Interface ------

descr("using_basic_input1","Basic camera is in use").
event_descr(recipient_rejects,"recording thrown out of court").
action_descr(patch(sam),"patch the SAM").

% ======== SIMPLE EXAMPLE 1 ========
%       -- to be used together with theory*.lp
% SYSTEM DESCRIPTION
% Input device 1 can operate in one of slow-mode and fast-mode.
% The SAM determines the mode of operation of input device 1.
% Normally, input device 1 reads inputs with a consistent frequency.
% If the basic type of input device 1 is configured to use
% encrypted memory and fast-mode, then the device will be
% unable to maintain a consistent frequency of reading.
%
% CONFIGURATION
% The SAM and input device 1 are configured to use encrypted 
% memory and secure boot. 
% The basic type of input device 1 is used.
% The SAM is configured to set input device 1 to slow-mode.
%
% Questions:
%   1. Is the functionality concern satisfied?
%   2. Is the functional aspect satisfied?
%   3. Are all aspects satisfied?
% 
% Answers:
%   1. Yes
%   2. Yes (because all concerns and sub-concerns of functional aspect are satisfied)
%   3. Yes (because all aspects are satisfied)

% ------ Initial state of the CPS ------

% Properties
% ---Observations
obs("encrypted_mem_input1",true).
obs("encrypted_mem_sam",true).
obs("sec_boot_input1",true).
obs("sec_boot_sam",true).
obs("slow_mode_input1",true).

% Extra-framework configuration
config_feature("using_basic_input1").
%%%%descr("using_basic_input1","Basic type of input device 1 is in use").
% the basic type of input device 1 is used, unless we decide otherwise
%assumed("using_basic_input1",true).
obs("using_basic_input1",true).

step(0).

% ------ Constraints ------

%   Normally, input device 1 reads inputs with a consistent frequency.
defined(neg,"consist_reading_freq_input1").
%assumed("consist_reading_freq_input1",true).

%   An exception to this general rule is that, when the basic type 
%   of input 1 device is in use, using encrypted memory and 
%   fast mode impacts negatively the maintainability of a consistent 
%   reading frequency"
impacted(neg,"consist_reading_freq_input1",S) :-
	step(S),
	holds("using_basic_input1",S),
	holds("encrypted_mem_input1",S),
	-holds("slow_mode_input1",S).


% ------ Output Interface ------

output(D,property,S) :- last_step(S), -holds(sat_property(A),S), atomic_statement(P,A), descr(P,D).
output(C,concern,S) :- last_step(S), -holds(sat_concern(C),S),-aspect(C).
output(C,aspect,S) :- last_step(S), -holds(sat_concern(C),S),aspect(C).
output("concern-tree",tree,S) :- last_step(S), -holds(sat_all,S).

output_headings("unsatisfied concern/aspect/property","type","step").
