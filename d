import React, { useState, useRef, useEffect } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Switch } from "@/components/ui/switch";
import {
  ShieldAlert,
  CloudRain,
  Thermometer,
  Wind,
  Layout,
  TrendingUp,
  Home,
  MapPin,
  Battery,
  Droplet,
  AlertTriangle,
  Mail,
  Settings
} from "lucide-react";
import { Chart } from "chart.js/auto";

/*************************************************
 * BioShield - Application d'optimisation agricole
 * Diffusion prédictive pilotée par l'IA
 *************************************************/

const DAILY_OIL_USAGE = 5; // en %/jour

const App = () => {
  // Fonction utilitaire pour définir la couleur du statut
  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case "actif":
        return "text-green-500";
      case "maintenance":
      case "faible huile":
        return "text-red-500";
      default:
        return "text-gray-300";
    }
  };

  // Fonction de calcul du score de risque prédictif
  const calculateRiskScore = (pest, humidity, temp, wind) => {
    const pestValue = typeof pest === "string" ? parseInt(pest, 10) : pest;
    const humidityValue = typeof humidity === "string" ? parseInt(humidity, 10) : humidity;
    const tempValue = typeof temp === "string" ? parseInt(temp, 10) : temp;
    const windValue = typeof wind === "string" ? parseInt(wind, 10) : wind;
    
    let score = pestValue * 2 + humidityValue / 2;
    if (tempValue >= 20 && tempValue <= 25) {
      score += 10;
    }
    if (windValue < 10) {
      score += 10;
    }
    return score;
  };

  // Seuil de risque à partir duquel la diffusion sera déclenchée
  const riskThreshold = 50;
  // Seuil d'intensité pour considérer que la diffusion est efficace
  const diffusionEffectivenessThreshold = 70;

  // Détermine si l'huile est efficace en se basant sur l'intensité de diffusion
  const isOilEffective = () => {
    const intensity = parseInt(sensorDiffusionIntensity, 10);
    return intensity >= diffusionEffectivenessThreshold ? "Efficace" : "Inefficace";
  };

  // Écran de bienvenue
  const renderWelcomeScreen = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] mb-4 transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-4 space-y-2">
        <h2 className="text-xl font-bold text-[#7BBF6A]">
          Bienvenue sur BioShield !
        </h2>
        <p className="text-sm text-[#F2EAE2]">
          Cette application vous permet de gérer vos diffuseurs d'huiles essentielles, 
          de suivre la météo et d’optimiser la diffusion grâce à une IA prédictive.
        </p>
      </CardContent>
    </Card>
  );

  // Navigation principale
  const [activePage, setActivePage] = useState("home");

  // Données environnementales (météo)
  const [weatherCondition, setWeatherCondition] = useState("Ensoleillé");
  const [weatherTemp, setWeatherTemp] = useState("18°C");
  const [windSpeed, setWindSpeed] = useState("12 km/h");
  const [soilHumidity, setSoilHumidity] = useState(50);

  // Capteurs AI (valeurs affichées)
  const [sensorTemp, setSensorTemp] = useState("18°C");
  const [sensorHumidity, setSensorHumidity] = useState("55%");
  const [sensorPest, setSensorPest] = useState("8%");
  const [sensorWind, setSensorWind] = useState("15 km/h");

  // Jauges liquides
  const [sensorWater, setSensorWater] = useState("80%");
  const [sensorEssentialOil, setSensorEssentialOil] = useState("65%");
  // Nouveau capteur pour mesurer l'intensité de diffusion dans l'air (en %)
  const [sensorDiffusionIntensity, setSensorDiffusionIntensity] = useState("0%");
  const [sensorSmokeLiquid, setSensorSmokeLiquid] = useState("50%");

  // Prévisions sur 3 jours (fictives)
  const [weatherForecast, setWeatherForecast] = useState([
    { day: "Demain", forecast: "Nuageux, 20°C" },
    { day: "+2 jours", forecast: "Pluvieux, 16°C" },
    { day: "+3 jours", forecast: "Ensoleillé, 22°C" },
  ]);

  // Statistiques nuisibles
  const [pestLevel, setPestLevel] = useState(12);
  const [historicalData, setHistoricalData] = useState(
    "Diminution de 35% des nuisibles cette saison"
  );

  // Diffuseurs et recherche  
  const [searchTerm, setSearchTerm] = useState("");
  const [diffusers, setDiffusers] = useState([
    {
      id: "#DIF-2025-01",
      battery: 75,
      oil: 60,
      status: "Actif",
      mode: "auto",
      location: "48.8566, 2.3522",
      lastEmission: Date.now() - 7200000,
      emissionMessage: ""
    },
    {
      id: "#DIF-2025-02",
      battery: 50,
      oil: 45,
      status: "Maintenance",
      mode: "desactive",
      location: "43.6047, 1.4442"
    },
    {
      id: "#DIF-2025-03",
      battery: 90,
      oil: 80,
      status: "Actif",
      mode: "auto",
      location: "45.7640, 4.8357",
      lastEmission: Date.now() - 7200000,
      emissionMessage: ""
    },
    {
      id: "#DIF-2025-04",
      battery: 65,
      oil: 30,
      status: "Faible huile",
      mode: "auto",
      location: "44.8378, -0.5792",
      lastEmission: Date.now() - 7200000,
      emissionMessage: ""
    },
    {
      id: "#DIF-2025-05",
      battery: 40,
      oil: 55,
      status: "Maintenance",
      mode: "desactive",
      location: "47.2184, -1.5536"
    },
  ]);

  // Référence pour le canvas du graphique
  const chartRef = useRef(null);
  const chartInstanceRef = useRef(null);

  // Calcul du temps avant remplacement de la cartouche
  const daysUntilCartridgeChange = (oilPercent) => {
    if (oilPercent <= 0) return 0;
    const daysLeft = oilPercent / DAILY_OIL_USAGE;
    return Math.ceil(daysLeft);
  };

  // Changer le mode d'un diffuseur (uniquement "auto" et "desactive")
  const handleChangeMode = (index, newMode) => {
    setDiffusers((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], mode: newMode };
      return updated;
    });
  };

  // Filtrer les diffuseurs par ID
  const filteredDiffusers = diffusers.filter((d) =>
    d.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Calcul récapitulatif global
  const totalDiffusers = diffusers.length;
  const activeCount = diffusers.filter((d) => d.status === "Actif").length;
  const maintenanceCount = diffusers.filter((d) => d.status === "Maintenance").length;
  const faibleHuileCount = diffusers.filter((d) => d.status === "Faible huile").length;

  // Simulation des données des capteurs de nuisibles (pour le graphique)
  const generateRandomSensorData = (numPoints) => {
    const data = [];
    const now = new Date();
    for (let i = 0; i < numPoints; i++) {
      let timestamp = new Date(now.getTime() - ((numPoints - i - 1) * 3600 * 1000));
      let pestRate = Math.floor(Math.random() * 101);
      data.push({ time: timestamp, pestRate });
    }
    return data;
  };

  // Initialisation du graphique dans la page "Statistiques"
  useEffect(() => {
    if (activePage === "statistics" && chartRef.current) {
      if (chartInstanceRef.current) chartInstanceRef.current.destroy();
      const sensorData = generateRandomSensorData(24);
      const labels = sensorData.map(item =>
        item.time.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
      );
      const pestRates = sensorData.map(item => item.pestRate);

      chartInstanceRef.current = new Chart(chartRef.current, {
        type: "line",
        data: {
          labels,
          datasets: [{
            label: "Taux de nuisibles (%)",
            data: pestRates,
            borderColor: "rgba(75, 192, 192, 1)",
            backgroundColor: "rgba(75, 192, 192, 0.2)",
            tension: 0.3,
            fill: true,
            pointRadius: 3
          }]
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: "Évolution du taux de nuisibles sur les 24 dernières heures"
            },
            legend: {
              display: true,
              position: "bottom"
            }
          },
          scales: {
            x: { title: { display: true, text: "Heure" } },
            y: { beginAtZero: true, max: 100, title: { display: true, text: "Taux (%)" } }
          }
        }
      });
    }
    return () => {
      if (chartInstanceRef.current) chartInstanceRef.current.destroy();
    };
  }, [activePage]);

  /*************************************************
   * AUTOMATISATION IA & DIFFUSION PRÉDICTIVE
   * - Toutes les 10 secondes, on simule la mise à jour des données des capteurs.
   * - L’IA calcule un score de risque à partir des capteurs.
   * - Le capteur "Diffusion Intensity" mesure la concentration d'arôme dans l'air.
   * - Si le score dépasse le seuil ET que le temps minimal entre diffusions est écoulé,
   *   on déclenche la diffusion.
   *************************************************/
  useEffect(() => {
    const interval = setInterval(() => {
      // Simulation des lectures des capteurs
      const newSoilHumidity = Math.floor(Math.random() * 61) + 20;
      setSoilHumidity(newSoilHumidity);

      const newSensorTemp = `${Math.floor(Math.random() * 15) + 10}°C`;
      setSensorTemp(newSensorTemp);

      const newSensorHumidity = `${Math.floor(Math.random() * 50) + 30}%`;
      setSensorHumidity(newSensorHumidity);

      const newPestValue = Math.floor(Math.random() * 20);
      setSensorPest(`${newPestValue}%`);

      const newSensorWind = `${Math.floor(Math.random() * 20) + 5} km/h`;
      setSensorWind(newSensorWind);

      setSensorWater(`${Math.floor(Math.random() * 50) + 50}%`);
      setSensorEssentialOil(`${Math.floor(Math.random() * 40) + 40}%`);
      setSensorSmokeLiquid(`${Math.floor(Math.random() * 40) + 30}%`);

      // Simulation de l'intensité de diffusion (par exemple, entre 60% et 100%)
      const newDiffusionIntensity = Math.floor(Math.random() * 41) + 60;
      setSensorDiffusionIntensity(`${newDiffusionIntensity}%`);

      const riskScore = calculateRiskScore(
        newPestValue,
        newSensorHumidity,
        newSensorTemp,
        newSensorWind
      );
      console.log("Score de risque prédictif :", riskScore);

      // Intervalle minimal fixe entre diffusions (2 heures)
      const fixedInterval = 7200000;
      setDiffusers((prevDiffusers) =>
        prevDiffusers.map((diffuser) => {
          if (diffuser.mode === "auto") {
            const now = Date.now();
            const lastEmission = diffuser.lastEmission || 0;
            let updated = { ...diffuser, status: newSoilHumidity < 30 ? "Actif" : "Inactif" };
            if (riskScore >= riskThreshold && now - lastEmission >= fixedInterval) {
              console.log(`Diffuser ${updated.id} diffuse l'huile (score: ${riskScore}).`);
              updated.lastEmission = now;
              updated.emissionMessage = `Diffusion lancée à ${new Date().toLocaleTimeString()}`;
            }
            return updated;
          }
          return diffuser;
        })
      );
    }, 10000);
    return () => clearInterval(interval);
  }, [sensorEssentialOil]);

  // Page Abonnement
  const renderSubscriptionPage = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-6 space-y-4">
        <h2 className="text-xl font-semibold text-[#EBC06C]">Abonnement en cours</h2>
        <p className="text-sm">
          Votre abonnement actuel est <span className="font-bold">Premium</span>, 
          combinant maintenance et réapprovisionnement.
        </p>
        <Button className="mt-4 bg-[#7BBF6A] text-white hover:bg-[#85C341]" size="sm">
          Modifier mon abonnement
        </Button>
      </CardContent>
    </Card>
  );

  // 1. Accueil
  const renderHome = () => (
    <>
      {renderWelcomeScreen()}
      <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl mt-4">
        <CardContent className="p-4 space-y-4">
          <h2 className="text-lg font-semibold text-[#EBC06C]">Récapitulatif</h2>
          <div className="grid grid-cols-1 gap-2 text-sm">
            <p>Total diffuseurs : <span className="font-bold">{totalDiffusers}</span></p>
            <p>Actifs : <span className="font-bold">{activeCount}</span></p>
            <p>Maintenance : <span className="font-bold">{maintenanceCount}</span></p>
            <p>Faible huile : <span className="font-bold">{faibleHuileCount}</span></p>
          </div>
        </CardContent>
      </Card>
      <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl mt-4">
        <CardContent className="p-4 space-y-4">
          <h2 className="text-lg font-semibold text-[#EBC06C]">Entretien annuel</h2>
          <p className="text-sm">
            Prochain entretien annuel prévu le <span className="font-bold">15/07/2025</span>.
          </p>
        </CardContent>
      </Card>
      <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl mt-4">
        <CardContent className="p-4 space-y-4">
          <h2 className="text-lg font-semibold text-[#EBC06C]">Conseils du jour</h2>
          <ul className="list-disc list-inside text-sm space-y-1">
            <li>Activez les notifications pour être alerté immédiatement en cas de risque élevé de nuisibles.</li>
            <li>Observez l’évolution du taux de nuisibles sur votre tableau de bord pour anticiper les périodes critiques.</li>
          </ul>
        </CardContent>
      </Card>
    </>
  );

  // 2. Météo
  const renderWeatherPage = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-4 space-y-4">
        <h2 className="text-lg font-semibold text-[#EBC06C]">Données environnementales</h2>
        <div className="flex items-center space-x-3">
          <CloudRain className="w-4 h-4 text-[#EBC06C]" />
          <p className="text-sm">Météo : {weatherCondition}</p>
        </div>
        <div className="flex items-center space-x-3">
          <Thermometer className="w-4 h-4 text-[#E46C6C]" />
          <p className="text-sm">Température : {weatherTemp}</p>
        </div>
        <div className="flex items-center space-x-3">
          <Wind className="w-4 h-4 text-[#F2CF63]" />
          <p className="text-sm">Vent : {windSpeed}</p>
        </div>
        <div className="flex items-center space-x-3">
          <Layout className="w-4 h-4 text-[#7BBF6A]" />
          <p className="text-sm">Humidité du sol : {soilHumidity}%</p>
        </div>
        <div className="mt-4 space-y-2">
          <h3 className="text-md font-semibold text-[#7BBF6A]">Prévisions</h3>
          {weatherForecast.map((wf, idx) => (
            <div key={idx} className="flex items-center space-x-2">
              <p className="text-sm font-bold">{wf.day} :</p>
              <p className="text-sm">{wf.forecast}</p>
            </div>
          ))}
          <p className="text-xs text-gray-400">Source : Météo Plein Champs</p>
        </div>
      </CardContent>
    </Card>
  );

  // 3. Statistiques (graphique + Capteurs AI)
  const renderStatisticsPage = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-4 space-y-4">
        <h2 className="text-lg font-semibold text-[#EBC06C]">Statistiques</h2>
        <div className="flex items-center space-x-3">
          <ShieldAlert className="w-4 h-4 text-[#E46C6C]" />
          <p className="text-sm">Nuisibles : {pestLevel}%</p>
        </div>
        <div className="flex items-center space-x-3">
          <TrendingUp className="w-4 h-4 text-[#7BBF6A]" />
          <p className="text-sm">Historique : {historicalData}</p>
        </div>
        <div className="mt-4">
          <canvas ref={chartRef} />
        </div>
        <div className="mt-6 p-4 border-t border-[#3A2B26]">
          <h3 className="text-md font-semibold text-[#7BBF6A] mb-2">Capteurs AI</h3>
          <div className="flex items-center space-x-3">
            <Thermometer className="w-4 h-4 text-[#E46C6C]" />
            <p className="text-sm">Température : {sensorTemp}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <Droplet className="w-4 h-4 text-[#EBC06C]" />
            <p className="text-sm">Humidité : {sensorHumidity}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <ShieldAlert className="w-4 h-4 text-[#E46C6C]" />
            <p className="text-sm">Nuisibles : {sensorPest}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <Wind className="w-4 h-4 text-[#F2CF63]" />
            <p className="text-sm">Vent : {sensorWind}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <Droplet className="w-4 h-4 text-[#7BBF6A]" />
            <p className="text-sm">Eau : {sensorWater}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <Droplet className="w-4 h-4 text-[#7BBF6A]" />
            <p className="text-sm">Huile essentielle : {sensorEssentialOil}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <Droplet className="w-4 h-4 text-[#7BBF6A]" />
            <p className="text-sm">Liquide de fumée : {sensorSmokeLiquid}</p>
          </div>
          <div className="flex items-center space-x-3 mt-2">
            <ShieldAlert className="w-4 h-4 text-[#7BBF6A]" />
            <p className="text-sm">
              Intensité de diffusion : {sensorDiffusionIntensity} - {isOilEffective()}
            </p>
          </div>
          <p className="mt-4 text-xs text-gray-400">
            L'efficacité est évaluée sur la concentration d'arôme détectée dans l'air.
          </p>
        </div>
      </CardContent>
    </Card>
  );

  // 4. Diffuseurs + modes + recherche
  const renderDiffusersPage = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-4 space-y-4">
        <h2 className="text-lg font-semibold text-[#EBC06C]">Liste des diffuseurs</h2>
        <div className="mb-4">
          <input
            type="text"
            placeholder="Rechercher un diffuseur (#ID)..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full p-2 rounded bg-[#3A2B26] text-[#F2EAE2] focus:outline-none text-xs"
          />
        </div>
        {filteredDiffusers.length === 0 ? (
          <p className="text-sm text-gray-300">Aucun diffuseur ne correspond à la recherche.</p>
        ) : (
          filteredDiffusers.map((d, idx) => {
            const daysLeft = daysUntilCartridgeChange(d.oil);
            return (
              <div
                key={d.id}
                className="border-b border-[#3A2B26] pb-2 mb-2 transition-all duration-300 hover:bg-[#3A2B26] rounded text-xs"
              >
                <p className="font-bold">ID : {d.id}</p>
                <div className="flex items-center space-x-1">
                  <Battery className="w-4 h-4 text-[#7BBF6A]" />
                  <p>Batterie : {d.battery}%</p>
                </div>
                <div className="flex items-center space-x-1">
                  <Droplet className="w-4 h-4 text-[#EBC06C]" />
                  <p>Huiles : {d.oil}%</p>
                </div>
                <p className={getStatusColor(d.status)}>Statut : {d.status}</p>
                {d.oil < 20 && (
                  <div className="flex items-center space-x-1 text-[#E46C6C]">
                    <AlertTriangle className="w-4 h-4" />
                    <p>Huile faible, remplacement bientôt nécessaire !</p>
                  </div>
                )}
                <p className="text-gray-400">
                  Changement de cartouche dans ~ {daysLeft} jour{daysLeft > 1 ? "s" : ""}.
                </p>
                <div className="flex items-center space-x-1 mt-1">
                  <MapPin className="w-4 h-4 text-[#E46C6C]" />
                  <p>Localisation : {d.location}</p>
                </div>
                <div className="mt-1">
                  <p className="mb-1">Mode :</p>
                  <div className="flex space-x-1">
                    <Button
                      size="xs"
                      className={
                        d.mode === "auto"
                          ? "bg-[#7BBF6A] text-white hover:bg-[#85C341]"
                          : "bg-[#3A2B26] text-[#F2EAE2] hover:bg-[#4A372F]"
                      }
                      onClick={() => handleChangeMode(idx, "auto")}
                    >
                      Auto
                    </Button>
                    <Button
                      size="xs"
                      className={
                        d.mode === "desactive"
                          ? "bg-[#E46C6C] text-white hover:bg-[#D15959]"
                          : "bg-[#3A2B26] text-[#F2EAE2] hover:bg-[#4A372F]"
                      }
                      onClick={() => handleChangeMode(idx, "desactive")}
                    >
                      Désactivé
                    </Button>
                  </div>
                </div>
                <p className="text-gray-400">Mode actuel : {d.mode}</p>
                {d.emissionMessage && (
                  <p className="text-xs text-[#7BBF6A]">Dernière action : {d.emissionMessage}</p>
                )}
              </div>
            );
          })
        )}
      </CardContent>
    </Card>
  );

  // 5. Nous contacter
  const renderContactPage = () => (
    <Card className="shadow-md bg-[#2C1F1B] text-[#F2EAE2] transition-all duration-300 hover:shadow-xl">
      <CardContent className="p-4 space-y-4 max-h-60 overflow-y-auto text-xs">
        <h2 className="font-semibold text-[#EBC06C]">Nous contacter</h2>
        <p>
          <strong>Nom de l'entreprise :</strong> BioShield SARL
        </p>
        <p>
          <strong>Adresse :</strong> 123 Rue de l'Agriculture, 75000 Paris, France
        </p>
        <p>
          <strong>Email :</strong> contact@bioshield.fr
        </p>
        <p>
          <strong>Téléphone :</strong> +33 1 23 45 67 89
        </p>
        <p className="text-gray-400">Disponibles du lundi au vendredi de 9h à 18h.</p>
      </CardContent>
    </Card>
  );

  // Router principal
  const renderContent = () => {
    switch (activePage) {
      case "home":
        return renderHome();
      case "weather":
        return renderWeatherPage();
      case "statistics":
        return renderStatisticsPage();
      case "diffusers":
        return renderDiffusersPage();
      case "subscription":
        return renderSubscriptionPage();
      case "contact":
        return renderContactPage();
      default:
        return renderHome();
    }
  };

  return (
    <div className="p-4 max-w-md mx-auto bg-[#231F20] text-[#F2EAE2] shadow-lg rounded-lg h-screen flex flex-col transition-all duration-300">
      <img
        src="https://i.imgur.com/NuGWBlj.jpeg"
        style={{ width: "20%", alignSelf: "center" }}
        alt="Logo BioShield"
      />
      <h1 className="text-3xl font-bold text-center text-[#7BBF6A] mb-2 transition-all duration-300 hover:text-[#85C341]">
        BioShield
      </h1>
      <div className="flex flex-wrap justify-around p-2 bg-[#2C1F1B] rounded-lg mb-4 transition-all duration-300">
        <Button variant="ghost" onClick={() => setActivePage("home")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <Home className="w-4 h-4" />
          <span>Accueil</span>
        </Button>
        <Button variant="ghost" onClick={() => setActivePage("weather")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <CloudRain className="w-4 h-4" />
          <span>Météo</span>
        </Button>
        <Button variant="ghost" onClick={() => setActivePage("statistics")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <TrendingUp className="w-4 h-4" />
          <span>Stats</span>
        </Button>
        <Button variant="ghost" onClick={() => setActivePage("diffusers")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <MapPin className="w-4 h-4" />
          <span>Diffuseurs</span>
        </Button>
        <Button variant="ghost" onClick={() => setActivePage("subscription")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <Settings className="w-4 h-4" />
          <span>Abonnement</span>
        </Button>
        <Button variant="ghost" onClick={() => setActivePage("contact")} className="text-[#F2EAE2] flex flex-col items-center hover:text-[#85C341] text-xs">
          <Mail className="w-4 h-4" />
          <span>Contact</span>
        </Button>
      </div>
      <div className="flex-1 overflow-y-auto">{renderContent()}</div>
    </div>
  );
};

export default App;
