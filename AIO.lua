 local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "Xerath.lua",
            Url = "raw.githubusercontent.com/qqwer1/GoS-Lua/master/External/LazyXerath.lua"
        }
         local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
