# Localizable.xcstrings - New Analytics Entries

## 📝 Instructions

Copy and paste the JSON below into your `Localizable.xcstrings` file. Add these entries to the existing JSON structure.

---

## 🔧 JSON to Add

```json
{
  "analytics.spent": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Spent"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Витрачено"
        }
      }
    }
  },
  "analytics.remaining": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Remaining"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Залишилось"
        }
      }
    }
  },
  "analytics.chart.amount": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Amount"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Сума"
        }
      }
    }
  },
  "analytics.chart.category": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Category"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Категорія"
        }
      }
    }
  },
  "analytics.chart.project": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Project"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Проект"
        }
      }
    }
  },
  "analytics.chart.type": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "stringUnit": {
          "state": "translated",
          "value": "Type"
        }
      },
      "uk": {
        "stringUnit": {
          "state": "translated",
          "value": "Тип"
        }
      }
    }
  }
}
```

---

## 📋 Quick Reference Table

| Key | English | Ukrainian | Purpose |
|-----|---------|-----------|---------|
| `analytics.spent` | Spent | Витрачено | Budget chart legend |
| `analytics.remaining` | Remaining | Залишилось | Budget chart legend |
| `analytics.chart.amount` | Amount | Сума | Chart dimension label |
| `analytics.chart.category` | Category | Категорія | Chart dimension label |
| `analytics.chart.project` | Project | Проект | Chart dimension label |
| `analytics.chart.type` | Type | Тип | Chart dimension label |

---

## 🎯 Where These Appear

### User-Visible (Chart Legends)
- **"Spent"** / **"Витрачено"** - Orange bar in budget utilization chart
- **"Remaining"** / **"Залишилось"** - Blue bar in budget utilization chart

### Accessibility (VoiceOver)
- **"Amount"** / **"Сума"** - Used in all charts for value descriptions
- **"Category"** / **"Категорія"** - Used in expense breakdown chart
- **"Project"** / **"Проект"** - Used in budget utilization chart
- **"Type"** / **"Тип"** - Used for grouping in budget chart

---

## ✅ Validation

After adding these entries, verify:

1. **Build succeeds** - No compilation errors
2. **English display** - Run app, check Analytics tab shows "Spent" and "Remaining"
3. **Ukrainian display** - Change language, check shows "Витрачено" та "Залишилось"
4. **VoiceOver** - Enable VoiceOver, verify proper announcements

---

## 🌍 Adding More Languages

To add another language (e.g., Spanish), add to each entry:

```json
{
  "analytics.spent": {
    "extractionState": "manual",
    "localizations": {
      "en": { "stringUnit": { "state": "translated", "value": "Spent" } },
      "uk": { "stringUnit": { "state": "translated", "value": "Витрачено" } },
      "es": { "stringUnit": { "state": "translated", "value": "Gastado" } }
    }
  }
}
```

### Suggested Spanish Translations

| Key | Spanish |
|-----|---------|
| `analytics.spent` | Gastado |
| `analytics.remaining` | Restante |
| `analytics.chart.amount` | Monto |
| `analytics.chart.category` | Categoría |
| `analytics.chart.project` | Proyecto |
| `analytics.chart.type` | Tipo |

### Suggested French Translations

| Key | French |
|-----|--------|
| `analytics.spent` | Dépensé |
| `analytics.remaining` | Restant |
| `analytics.chart.amount` | Montant |
| `analytics.chart.category` | Catégorie |
| `analytics.chart.project` | Projet |
| `analytics.chart.type` | Type |

---

**Last Updated**: March 13, 2026  
**Keys Added**: 6  
**Languages**: English, Ukrainian (+ suggestions for Spanish, French)
