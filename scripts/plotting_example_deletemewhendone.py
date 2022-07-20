import matplotlib as mp
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.ticker import LinearLocator, FormatStrFormatter
from scipy import interpolate
import numpy as np
from mpl_toolkits.mplot3d.axes3d import Axes3D
from mpl_toolkits.mplot3d import proj3d
import matplotlib.colors as colors

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

x = [5, 10, 15, 17.5, 20, 35, 50, 200, 320, 400,]
y = [0, 5, 10, 15, 20, 25, 30, 35, 40]
Y,X=np.meshgrid(y,x)
Z = np.array([
[151.89,	131.7,	117.33,	107.75,	102.9,	99.4,	97,	95.25,	93.99],
[147.37,	130.55,	116.29,	106.55,	100.91,	97.3,	95.06,	93.52,	92.06],
[144.41,	128.36,	113.87,	103.99,	98.47,	95.32,	92.78,	90.76,	89.16],
[141.48,	123.85,	109.45,	99.72,	94.52,	91.3,	88.64,	87.34,	85.62],
[139.32,	121.96,	107.39,	97.38,	91.88,	88.61,	86.42,	85,	84.05],
[137.11,	120.34,	105.52,	94.4,	88.7,	85.27,	83.45,	84.14,	80.88],
[136.81,	119.55,	103.76,	93.62,	87.41,	84.22,	81.84,	80.12,	78.96],
[137.77,	120.3,	103.49,	88.74,	76.18,	66.91,	60.37,	56.15,	53.42],
[138.42,	120.89,	103.77,	88.31,	73.77,	62.35,	56.31,	51.51,	47.97],
[138.42,	120.89,	103.77,	88.31,	73.77,	62.35,	56.31,	51.51,	47.97],

])

cost = np.array([[1796. * solar + 500. * batt + 35 * 1217. for solar in y] for batt in x])

payback = np.array([
[220,9.727340588,10.24984125,11.08950752,11.91716504,12.61373853,13.19862977,13.68853829,14.10194094],
[220,12.41160073,11.64562957,11.88038875,12.48627031,13.05928737,13.56402949,14.00059486,14.37334368],
[220,14.85446561,12.89610693,12.59303137,12.98355295,13.44828315,13.89075021,14.28176646,14.61960989],
[220,17.38541265,14.1282577,13.33791155,13.48024512,13.83165729,14.20763631,14.55543529,14.86030991],
[220,18.69836732,14.73767171,13.72489924,13.72645558,14.02262142,14.3636183,14.68961325,14.97865129],
[220,20.01642803,15.34482843,14.1157586,13.97388554,14.21484053,14.51926437,14.8220387,15.09560866],
[220,27.92450299,19.04156122,16.6144916,15.61016239,15.42160744,15.51269723,15.67032852,15.84221144],
[220,35.83136621,22.91429437,19.18082026,17.48539935,16.80469916,16.65539859,16.68539463,16.76350691],
[220,114.8522666,62.7319256,45.59653642,37.30899098,33.10175954,30.93424762,29.44567565,28.29762609],
[220,220.0736648,115.8682357,56.43935108,52.52459961,49.35230581,46.72966057,44.52520036,42.64629017],
[220,220.0736648,115.8682357,56.43935108,52.52459961,49.35230581,46.72966057,44.52520036,42.64629017],

])
#payback = np.array([[payback_[j][i] for i in range(len(x))] for j in range(len(y))])

carbon = np.array([
[13886.80948,	11571.24212,	9936.005312,	8860.339453,	8315.06475,	7921.210058,	7650.496041,	7451.664586,	7306.422476],
[13137.34709,	11253.94106,	9671.434147,	8582.15427,	7955.378606,	7551.759622,	7302.195478,	7123.030889,	6960.823536],
[12771.79248,	10980.24448,	9366.485234,	8260.180561,	7644.966641,	7292.177806,	7005.279429,	6783.979494,	6603.321181],
[12440.30041,	10469.54232,	8857.629795,	7778.660529,	7198.014481,	6836.061254,	6540.521891,	6392.492936,	6201.284262],
[12190.42968,	10252.40811,	8626.228723,	7511.432771,	6896.573279,	6533.596136,	6285.996022,	6201.284262,	6020.98896],
[11929.43697,	10058.91982,	8404.442023,	7163.539215,	6527.031892,	6143.552513,	5939.894568,	5794.208598,	5653.526519],
[11895.49849,	9969.388194,	8207.547777,	7075.072985,	6381.267986,	6025.920719,	5759.67378,	5567.388806,	5437.939007],
[12003.20799,	10053.33954,	8177.586555,	6530.826197,	5128.49274,	4094.625696,	3364.71391,	2893.75921,	2588.469003],
[12075.95245,	10119.70735,	8209.150342,	6482.992643,	4860.009798,	3586.202645,	2911.802136,	2376.495165,	1980.872138],
[12075.95245,	10119.70735,	8209.150342,	6482.992643,	4860.009798,	3586.202645,	2911.802136,	2376.495165,	1980.872138],

])

#zinterp = interpolate.interp2d(X, Y, Z, kind='cubic')
#winterp = interpolate.interp2d(X, Y, cost, kind='cubic')
#carboninterp = interpolate.interp2d(X, Y, carbon, kind='cubic')

#zinterp = interpolate.Rbf(X, Y, Z, kind='linear')
#winterp = interpolate.Rbf(X, Y, cost, kind='linear')
#carboninterp = interpolate.Rbf(X, Y, carbon, kind='linear')

#new_x = [5, 10, 15, 17.5, 20, 35, 50, 75, 100, 125, 150, 175, 200,250, 300, 350, 400]#np.linspace(min(x), max(x), 20)
#new_y= [0, 2, 5, 7, 10, 12, 15, 17, 20, 22, 25, 28, 30, 33, 35, 37, 40]#np.linspace(min(y), max(y), 20)
#new_x = np.linspace(min(x), max(x), 400)
#new_y= np.linspace(min(y), max(y), 400)
#new_Z = zinterp(new_x, new_y)
#new_cost = winterp(new_x, new_y)
#new_carbon = carboninterp(new_x, new_y)
#new_Y, new_X = np.meshgrid(new_y,new_x)

x_scale=2
y_scale=2
z_scale=1.5

scale=np.diag([x_scale, y_scale, z_scale, 1.0])
scale=scale*(1.0/scale.max())
scale[3,3]=1.0

def short_proj():
  return np.dot(Axes3D.get_proj(ax), scale)

ax.get_proj=short_proj



# Plot capital cost vs EUI vs battery vs solar
#normcost = mp.colors.Normalize(vmin=new_cost.min().min(), vmax=new_cost.max().max())
#ax.plot_surface(new_X, new_Y, new_Z, facecolors=plt.cm.jet(normcost(new_cost)), antialiased=True, cstride=1, rstride=1)
#ax.set_title('Cost and EUI of different configurations', fontsize=12, fontweight='bold')
#ax.set_xlabel('Battery capacity [kWh]', fontsize=12, fontweight='bold', labelpad=10)
#ax.set_ylabel('Solar capacity [kW]', fontsize=12, fontweight='bold', labelpad=10)
#ax.set_zlabel('EUI', fontsize=12, fontweight='bold', labelpad=10)

#normcost = mp.colors.Normalize(vmin=cost.min().min(), vmax=cost.max().max())
normcost = colors.Normalize(vmin=5, vmax=30)#payback.max().max()) payback.min().min()
#normcost = colors.LogNorm(vmin=cost.min().min(), vmax=cost.max().max())

#ax.plot_surface(X, Y, Z, facecolors=plt.cm.jet(normcost(cost)))#, antialiased=True, cstride=1, rstride=1)
ax.plot_surface(X, Y, Z, facecolors=plt.cm.jet(normcost(payback)))#, antialiased=True, cstride=1, rstride=1)

ax.set_title('Payback and EUI of different configurations', fontsize=12, fontweight='bold')
ax.set_xlabel('Battery capacity [kWh]', fontsize=12, fontweight='bold', labelpad=10)
ax.set_ylabel('Solar capacity [kW]', fontsize=12, fontweight='bold', labelpad=10)
ax.set_zlabel('EUI', fontsize=12, fontweight='bold', labelpad=10)

ax.set_ylim([40, 0])
#ax.view_init(30, 30)
#ax.set_yticklabels([40, 35, 30, 25, 20, 15, 10, 5, 0])
m = cm.ScalarMappable(cmap=cm.jet, norm=normcost)
m.set_array([])
cbar = plt.colorbar(m, location='bottom', shrink = 0.5, format='%d')
#cbar.set_label('Cost [US$]', fontsize=12, fontweight='bold')#shrink=0.5)
cbar.set_label('Payback [years]', fontsize=12, fontweight='bold')#shrink=0.5)


##ax.zaxis.set_major_locator(LinearLocator(10))
#ax.zaxis.set_major_formatter(FormatStrFormatter('%.02f'))

# Plot emissions vs EUI vs battery vs solar
plt.show()
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

#normcarbon = mp.colors.Normalize(vmin=new_carbon.min().min(), vmax=new_carbon.max().max())
#ax.plot_surface(X, Y, Z, facecolors=plt.cm.jet(normcarbon(new_carbon)), antialiased=True)
#ax.set_title('Cost and EUI of different configurations', fontsize=12, fontweight='bold')
#ax.set_xlabel('Battery capacity [kWh]', fontsize=12, fontweight='bold', labelpad=10)
#ax.set_ylabel('Solar capacity [kW]', fontsize=12, fontweight='bold', labelpad=10)
#ax.set_zlabel('EUI', fontsize=12, fontweight='bold', labelpad=10)

normcarbon = mp.colors.Normalize(vmin=carbon.min().min(), vmax=carbon.max().max())
ax.plot_surface(X, Y, Z, facecolors=plt.cm.jet(normcarbon(carbon)), antialiased=True)
ax.set_title('Cost and EUI of different configurations', fontsize=12, fontweight='bold')
ax.set_xlabel('Battery capacity [kWh]', fontsize=12, fontweight='bold', labelpad=10)
ax.set_ylabel('Solar capacity [kW]', fontsize=12, fontweight='bold', labelpad=10)
ax.set_zlabel('EUI', fontsize=12, fontweight='bold', labelpad=10)

ax.set_ylim([40, 0])
m = cm.ScalarMappable(cmap=cm.jet, norm=normcarbon)
m.set_array([])
cbar = plt.colorbar(m, location='bottom', shrink=0.5)
cbar.set_label('Carbon emissions [kgCO2e]', fontsize=12, fontweight='bold')#shrink=0.5)
ax.get_proj=short_proj
plt.show()

