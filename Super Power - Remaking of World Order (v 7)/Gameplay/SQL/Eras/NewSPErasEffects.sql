insert into Trait_EraMountainCityYieldChanges
select 'TRAIT_GREAT_ANDEAN_ROAD', Type, 'YIELD_SCIENCE', ID + 1 from Eras
union select 'TRAIT_GREAT_ANDEAN_ROAD', Type, 'YIELD_FOOD', ID + 1 from Eras;

insert into Trait_EraCoastCityYieldChanges
select 'TRAIT_WAYFINDING', Type, 'YIELD_CULTURE', ID + 1 from Eras
union select 'TRAIT_WAYFINDING', Type, 'YIELD_PRODUCTION', ID + 1 from Eras;