# qb-dumpster
Five m qbus Dumpster Script Using qb-target to Hide/Storage

# INSTALL
# 1/
add dumpster.lua to qb-smallresources/cliant

#2/
add to qb-smallresources/config.lua
----------------------------------------
---- // dumpsters
Config.Dumpster = {
	canHide = false, -- enable/disable hiding in dumpsters
	storage = false, -- eanble/disable dumpster storage

	-- storage weight and slots
	-- note: bins use half
	weight = 100000,
	slots = 50,

	-- [[ MODELS ]] --
	-- dumpsters: used for storage and hiding
	dumpsters = {
		`prop_dumpster_01a`,
		`prop_dumpster_02a`,
		`prop_dumpster_02b`,
		`prop_dumpster_3a`,
		`prop_dumpster_4a`,
		`prop_dumpster_4b`,
	},
	-- trash bins: used only for storage
	bins = { -- trash bin models
		`prop_bin_08a`,
		`prop_bin_01a`,
		`prop_bin_07c`,
		`prop_bin_07a`,
		`prop_cs_bin_02`,
		`prop_recyclebin_04_b`,
		`prop_bin_05a`,
		`prop_bin_02a`
	}
}
 --------------------------------------------------
# all done

# discord : https://discord.gg/UagxbvDG
