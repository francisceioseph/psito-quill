-- O primeiro plugin do Quill: prova que o Lua 5.4 roda na caixa de areia.
-- Na Fase 0 a API é só psito.log; a psito.* completa vem na Fase 5.
local partes = {}
for palavra in ("olá do Lua"):gmatch("%S+") do
  partes[#partes + 1] = palavra
end
psito.log(table.concat(partes, " ") .. " (" .. _VERSION .. ")")
