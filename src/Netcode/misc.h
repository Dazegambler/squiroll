#pragma once

#include <cstddef>
#ifndef MISC_H
#define MISC_H 1

#include "TF4.h"
#include <vector>
#include <functional>

// struct Rule {
//     int32_t duration;
//     std::function<void(ManbowActor2D*)> rule;

//     Rule(int32_t duration, std::function<void(ManbowActor2D*)> rule){
//         this->duration = duration;
//         this->rule = rule;
//     }
// };

// struct Ruleset {
//     int32_t index;
//     int32_t size;
//     Rule rules[];

//     Ruleset(Rule rules[]) {
//         this->rules = rules;
//         this->size = sizeof(this->rules) / sizeof(Rule);
//     }
// };

// struct RuleManager {
//     Ruleset* rotation;
//     int32_t frame;

//     void Apply(ManbowActor2D* actor) {
//         this->rotation->rules[this->rotation->index].rule(actor);
//         // if (--current.duration < 1){
//         //     if(++this->rotation->index >= this->rotation->size)this->rotation->index = 0;
//         // }       
//     }
// };

#endif