const translations = {
  en: {
    appTitle: "AeraSync",
    start: "Start",
    next: "Next",
    back: "Back",
    submit: "Submit",
    results: "Results",
    home: {
      welcome: "Welcome to AeraSync",
      description:
        "Compare aerators for shrimp farming with a step-by-step survey and view ranked results.",
    },
    survey: {
      title: "Aerator Survey",
      step1: "Basic Information",
      step2: "Farm Details",
      step3: "Power Source",
      step4: "Preferences",
    },
    results: {
      title: "Comparison Results",
      summary: "Summary",
      totalCost: "Total Cost",
      efficiency: "Efficiency",
      recommendation: "Recommendation",
    },
  },
  es: {
    appTitle: "AeraSync",
    start: "Comenzar",
    next: "Siguiente",
    back: "Atrás",
    submit: "Enviar",
    results: "Resultados",
    home: {
      welcome: "Bienvenido a AeraSync",
      description:
        "Compare aireadores para cultivo de camarones con una encuesta paso a paso y vea resultados clasificados.",
    },
    survey: {
      title: "Encuesta de Aireadores",
      step1: "Información Básica",
      step2: "Detalles de la Granja",
      step3: "Fuente de Energía",
      step4: "Preferencias",
    },
    results: {
      title: "Resultados de Comparación",
      summary: "Resumen",
      totalCost: "Costo Total",
      efficiency: "Eficiencia",
      recommendation: "Recomendación",
    },
  },
};

export const getTranslations = async (lang) => {
  const userLang = lang || navigator.language.split("-")[0] || "en";
  return translations[userLang] || translations["en"];
};
