
% Dynamic storage for yes/no answers


% store user inputted answers dynamically
:- dynamic yes/1, no/1. % answers received will be based on yes and no
:- dynamic has_symptom/1. % if a user says yes to a symptom store this under has symptom
:- dynamic bio/2. % I will be storing biological information
:- dynamic recent_event/1. % store exposure events that the user says yes to

% write questions and store response
ask(Question) :-
    write(Question),
    read(Reply),
    (Reply == y ; Reply == yes).
% Show the question on the screen, read the user's response and store the response if the user answers yes

% verify user generated response - if the user says yes store as answer, if the user says no store as no and do not ask the same question twice
verify(S) :-
    ( yes(S) -> true
    ; no(S)  -> fail
    ; ( ask(S) -> assert(yes(S))
      ; assert(no(S)), fail )
    ).

% Clears all of the stored previous yes and no answers
undo :-
    retract(yes(_)), fail.
undo :-
    retract(no(_)), fail.
undo.

% Clears all of the other stored facts about the patient eg. if they have symptoms or biological risk factors
clear :-
    retractall(has_symptom(_)),
    retractall(bio(_, _)),
    retractall(recent_event(_)),
    undo.


% Symptom, Risk and Exposure Facts


% list all common symptoms and store each defined symptom as common
common_symptom(a_fever).
common_symptom(a_dry_cough).
common_symptom(tiredness).

% list all less common symptoms and store each defined symptom as less common
less_common_symptom(aches_and_pains).
less_common_symptom(a_sore_throat).
less_common_symptom(diarrhoea).
less_common_symptom(conjunctivitis).
less_common_symptom(a_headache).
less_common_symptom(loss_of_smell).
less_common_symptom(loss_of_taste).
less_common_symptom(a_runny_nose).

% list all serious symptoms and store each defined symptom as serious
serious_symptom(difficulty_breathing).
serious_symptom(chest_pain).
serious_symptom(loss_of_speech).
serious_symptom(loss_of_movement).


% list all pre-existing conditions as risk conditions
risk_condition(hypertension).
risk_condition(diabetes).
risk_condition(a_cardiovascular_disease).
risk_condition(a_respiratory_disease).
risk_condition(cancer).


% list all exposure events and store as recent exposure indicators
recent_exposure(had_close_contact_with_infected_person).
recent_exposure(touched_a_contaminated_surface).
recent_exposure(travelled_to_virusville).


% Questions required to ascertain patient answers


ask_symptom(S) :-
    atom_string(S, Str),
    string_concat("Do you have ", Str, P1),
    string_concat(P1, " (y/n)? ", Question),
    ( ask(Question) ->
        assert(has_symptom(S))
    ; true ). % check if they have any symptoms by asking questions and expecting answer then store the answer

ask_condition(C) :-
    atom_string(C, Str),
    string_concat("Do you have ", Str, P1),
    string_concat(P1, " (y/n)? ", Question),
    ( ask(Question) ->
        assert(bio(condition, C))
    ; true ). %check if they have any pre-existing conditions by asking questions and expecting answer then store the answer

ask_event(E) :-
    atom_string(E, Str),
    string_concat("Have you ", Str, P1),
    string_concat(P1, " (y/n)? ", Question),
    ( ask(Question) ->
        assert(recent_event(E))
    ; true ). % check if they have been exposed by asking questions and expecting answer then store the answer

ask_age :-
    write("Are you over 70 (y/n)? "),
    read(Reply),
    (Reply == y ->
        assert(bio(age_risk, yes))
    ;
        assert(bio(age_risk, no))
    ). % check if they are over 70 and store the answer as a biological factor

ask_sex :-
    write("Are you male (y/n)? "),
    read(Reply),
    (Reply == y ->
        assert(bio(sex_risk, yes))
    ;
        assert(bio(sex_risk, no))
    ). % check if they are male - if they are female the answer will be no and they are lower risk. Store as a biological factor


% Ask all symptoms, conditions, events


ask_all_symptoms :-
    nl, write("Common symptoms:"), nl,
    forall(common_symptom(S), ask_symptom(S)),
    nl, write("Less common symptoms:"), nl,
    forall(less_common_symptom(S), ask_symptom(S)),
    nl, write("Serious symptoms:"), nl,
    forall(serious_symptom(S), ask_symptom(S)). % ask if a patient has got any of the possible symptoms broken down into lists of common, less common and serious

ask_all_conditions :-
    nl, write("Pre-existing conditions:"), nl,
    forall(risk_condition(C), ask_condition(C)). % ask if a patient has any pre-existing conditions

ask_all_events :-
    nl, write("Exposure events:"), nl,
    forall(recent_exposure(E), ask_event(E)). % ask if a patient has been exposed in any of the listed ways


% Diagnostic Logic for determining severity of the case


has_common_symptom :-
    has_symptom(S),
    common_symptom(S). % store if patient has any common symptoms

has_less_common_symptom :-
    has_symptom(S),
    less_common_symptom(S). % store if patient has any less common symptoms

has_serious_symptom :-
    has_symptom(S),
    serious_symptom(S). % store if patient has any serious symptoms

has_any_symptom :-
    has_symptom(_). % store if patient has confirmed a symptom

has_condition :-
    bio(condition, C),
    risk_condition(C). % if a patient has a biological condition ensure this is noted for classification


high_risk :-
    bio(age_risk, yes);
 % if the patient is over 70 store this as a biological risk
    (bio(sex_risk, yes), has_condition).
 % if the patient is male and has a condition, store this as high risk

exposed :-
    recent_event(E),
    recent_exposure(E).
 % if exposure event is confirmed, save the event.

symptom_count(N) :-
    findall(S, has_symptom(S), L),
    length(L, N).
 % store the number of confirmed symptoms in a list and count number of symptoms

% Classification rules

diagnosis(severe_case_emergency) :-
    has_serious_symptom.
 % if the patient has a serious symptom then treat this as an emergency.

diagnosis(mild_case_high_risk) :-
    \+ has_serious_symptom,
    (has_common_symptom ; has_less_common_symptom),
    high_risk.
 % if  the patient does not have a severe symptom but does have a common and less common symptom and is high risk, treat this as a mild case with high risk

diagnosis(mild_case_stay_home) :-
    \+ has_serious_symptom,
    (has_common_symptom ; has_less_common_symptom),
    \+ high_risk.
 % if the patient does not have any serious symptoms and is not high risk but is showing other symptoms classify as mild case and to stay at home

diagnosis(moderate_case_consult_doctor) :-
    symptom_count(N),
    N >= 3,
    has_condition,
    \+ has_serious_symptom.
 % if a patient has more than 3 symptoms and has a condition but does not have any serious symptoms, treat this as a moderate case and ensure they consult a doctor

diagnosis(yes_likely) :-
    has_common_symptom,
    exposed.
 % if a patient has got a common symptom and has been exposed then consider them likely to have been infected

diagnosis(yes_possible) :-
    has_less_common_symptom,
    exposed.
 % if a patient has a less common symptom and has been exposed then consider it possible for them to have been infected

diagnosis(patient_exposed_potential_asymptomatic) :-
    exposed,
    \+ has_any_symptom.
 % if a patient has been exposed to the virus but is not showing any symptoms display as potentially asymptomatic

diagnosis(low_risk_of_infection) :-
    \+ has_any_symptom,
    \+ exposed.
 % if a patient has not got any symptoms and has not been exposed then consider them to be low risk


% Recommended Actions


action(requires_emergency_medical_attention) :-
    diagnosis(severe_case_emergency).
 % if this is a severe case, ensure that the emergancy protocol is enforced

action(home_care_plus_checkins) :-
    diagnosis(mild_case_high_risk).
 % if the patient is high risk, ensure that they are receiving regular check ins

action(home_care) :-
    diagnosis(mild_case_stay_home).
 % if there is a mild case present, recommend that the patient stays home to recover

action(call_doctor_assessment) :-
    diagnosis(moderate_case_consult_doctor).
 % if diagnosis is moderate risk of infection, request that the patient call doctor

action(quarantine_14_days) :-
    diagnosis(patient_exposed_potential_asymptomatic);
    diagnosis(yes_likely);
    diagnosis(yes_possible).
 %if the patient has been exposed but is not showing symptoms, recommend a 14 day quarantine period

action(reassure_and_monitor) :-
    diagnosis(low_risk_of_infection).
 % check that there is low risk to patient and reassure them that they will be okay


% Logic to Start the process and provide the diagnosis and recommendation based on answers


go :-
    clear,
    nl, write("- Virusville Diagnosis Expert - Please answer y. or n. to the below questions:-"), nl,
 % Title of the application

    % Ask questions to determine patient's current state
    ask_age,
    ask_sex,
    ask_all_symptoms,
    ask_all_conditions,
    ask_all_events,

    % Confirm diagnosis and recommendation to the patient
    ( diagnosis(Result) ->
        nl, write("Diagnosis: "), write(Result), nl,
        action(Action),
        write("Recommended action: "), write(Action), nl
    ;
    % If there is no diagnosis, recommend reassuring the patient and monitoring the symptoms
        nl, write("Diagnosis: no clear indication of infection."), nl,
        write("Recommended action: reassure_monitor"), nl
    ).
