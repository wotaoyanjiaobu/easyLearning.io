require('nn')
require('cunn')
require('image')

torch.setdefaulttensortype('torch.FloatTensor')

local fixedCNN = torch.load('fixedCNN.t7');
fixedCNN:evaluate()

-- input is 56x56
local featureCNN = nn.Sequential()

featureCNN:add( nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1) )
featureCNN:add( nn.ReLU(true) )
featureCNN:add( nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1) )
featureCNN:add( nn.ReLU(true) )
featureCNN:add( nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1) )
featureCNN:add( nn.ReLU(true) )
featureCNN:add( nn.SpatialMaxPooling(2, 2, 2, 2, 0, 0):ceil() )

local mbox = nn.ConcatTable()
local allBoxes = { {2,2}, {3,3}, {4,4}, {5,5}, {6,6}, {7,7}, 
                   {2,4}, {4,2}, 
                   {3,6}, {6,3} }

for i = 1, #allBoxes do
    local boxConf = nn.Sequential()
    boxConf:add(nn.SpatialConvolution(512, 256, 1, 1, 1, 1, 0, 0))
    boxConf:add(nn.ReLU(true))
    boxConf:add(nn.SpatialConvolution(256, 21, allBoxes[i][1], allBoxes[i][2], 1, 1, 0, 0))
    boxConf:add(nn.SpatialLogSoftMax())
    mbox:add(boxConf)
 
    local boxLoc = nn.Sequential()
    boxLoc:add(nn.SpatialConvolution(512, 256, 1, 1, 1, 1, 0, 0))
    boxLoc:add(nn.LeakyReLU(0.1))
    boxLoc:add(nn.SpatialConvolution(256,  4, allBoxes[i][1], allBoxes[i][2], 1, 1, 0, 0))
    mbox:add(boxLoc)
end

featureCNN:add(mbox)

--[[
fixedCNN:cuda()
featureCNN:cuda()
local x = torch.rand(4, 3,256,256):cuda()
local y = featureCNN:forward( fixedCNN:forward(x) )
print(y)
--]]

return {allBoxes, fixedCNN, featureCNN}